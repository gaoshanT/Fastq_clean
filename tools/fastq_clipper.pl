#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Getopt::Long;
use List::Util;

my $usage = <<_EOUSAGE_;

#################################################################################
# $0 --file_list <FILE>  --suffix [String] --distance [INT] --levenshtein 
#		 --max_N [INT] --min_Len [INT] --CPU <INT> --shuffle
#
# Required(1):
#  --file_list	a file containing a list of sample to be process;one cmd per line.
#				"Sample_name_with_suffix\tRev_com_adapter_seq\tAdapter_offset_From_5end\n"
# Options(7):
#  --suffix	    the suffix of the input files [fastq]
#  --distance       the largest edit distance can be allowed between a adapter and reads [2]
#  --levenshtein       using levenshtein distance, default is hamming distance [Not use]
#  --max_N	only report reads containing no more than given number of 'N' after trimming [0]
#  --min_Len	only report reads not shorter than given Length after trimming [15]
#  --CPU	Number of processors to use [4]    
#  --shuffle	randomly orders the commands before executing them [Not use]
###################################################################################

_EOUSAGE_
	;
# 此程序源于trinity软件包，原本用于运行butterfly_commands.adj(每行一个命令)	
# 一个命令将调用一个linux进程，因此注释中命令、进程和任务是一个意思
#################
##   全局变量  ##
#################
our $file_list = "";
our $suffix="fastq";          #输入文件（fastq格式）的后缀名
our $distance=2;        #adapter与read匹配时可允许的最大编辑距离，目前最多是1
our $levenshtein=0;#如果设定，此值自动转为1，表示使用levenshtein算法求编辑距离
our $max_N=0;     #剩下的reads中，剩下的N不能大于这个数
our $min_Len=15; #最后留下的reads必须大于等于15bp长度

our $CPU = 4;
our $shuffle_flag = 0;
our $ENCOUNTERED_FAILURE = 0; #全局变量，子程序中继承
#################
## 输入参数处理##
#################
&GetOptions (
			 "file_list=s" => \$file_list,#需要执行的命令所在的文件			 
			 'suffix=s' => \$suffix,
             'distance=i' => \$distance,
	         'levenshtein!' => \$levenshtein,		 
			 'max_N=i' => \$max_N,
			 'min_Len=i' => \$min_Len,
			 "CPU=i" => \$CPU,
             "shuffle" => \$shuffle_flag			 
             );

unless ($file_list) { #最重要参数必须有
	die $usage;
}

my $log_dir = "cmds_log.$$";
mkdir($log_dir) or die "Error, cannot mkdir $log_dir";

#############
##  主程序 ##
#############
main: {
	# 输出统计信息每列的名字
	print "Sample\tRaw_reads\tRaw_length\tNull_reads\tUnmatched_reads\tTrimmed_reads\tTrimmed_ratio(%)\tCleaned_reads\tCleaned_length\n";	
	my %job_tracker;		# 记录需要跟踪的命令总数
	my @failed_jobs;		# 记录失败的任务
	my $num_running = 0;	
    my @unix_cmds;  #这个数组记录所有的命令行
	
    #从文件中逐行读入命令行	
	open (my $fh, $file_list) or die "Error, cannot open file $file_list";      
	while (my $cmd = <$fh>) {
		chomp $cmd;
		push (@unix_cmds, $cmd);#用一个数组存储所有命令
	}
	close $fh;
	
	#打乱所有命令的顺序，目的是把运行时间长的（假如在前）和短的命令（假如在后）均匀一下
    if ($shuffle_flag) {
        @unix_cmds = shuffle(@unix_cmds);
    }
	
    my $cmd_counter = 0;
    foreach my $cmd (@unix_cmds) {	# 逐条执行所有命令
        $cmd_counter++;      
		$num_running++;	#记录当前正在运行的命令数量
        
		my $pid = fork();	#每次一分为二，产生的子进程和父进程除了pid完全一样，并进入父进程所在的可执行队列里等待调度
		if ($pid) { #$pid值非0，当前进程是父进程（调度到运行态），继续fork子进程
			$job_tracker{$cmd_counter} = $cmd; #记录所有开始运行的进程
		}
		else {#$pid值为0，当前进程是子进程（调度到运行态），运行cmd命令，然后退出，否则没完没了
			my $ret = &run_cmd($cmd_counter, $cmd);
			exit($ret);  #如果执行上一条命令失败，则退出当前进程
		}
		
		if ($num_running >= $CPU) { #若已分配进程数大于cpu数量,">"可以不要
			wait(); # 暂停当前进程执行
			my $num_finished = &collect_jobs(\%job_tracker, \@failed_jobs);   #统计统计已经成功结束或者失败的进程，并更新%job_tracker
			$num_running -= $num_finished; # 正在运行的进程数量减去已经完成的，更新
           		
            #避免僵尸进程(Zombie process)，这个为什么这么写还不理解 
            for (1..$num_finished-1) {
                wait();
            }
           
		}
	} # 逐条执行所有命令结束
	
	# 不断判定wait()的返回值，直到没有子进程
	while (wait() != -1) { };	#不需要参数，wait() 返回值为子进程ID，如果没有子进程，返回-1。
								#当所有命令执行结束，最后几个进程（进程数恰好等于或者小于规定进程）的子进程在此处等待结束
	&collect_jobs(\%job_tracker, \@failed_jobs); #对以上进程进行回收	
	# 全部命令运行完毕，删除log文件夹
	`rm -rf $log_dir`;
	
	
	# 以下是结果报告	
	my $num_failed_jobs = scalar @failed_jobs; #计录失败任务的数量
	if (! $ENCOUNTERED_FAILURE) {#如果这个标志变量为0，表示全部成功运行完毕
		print "\nAll $cmd_counter jobs completed successfully! \n";
		exit(0);
	}
	else {# 如果这个标志变量不为0
        unless ($num_failed_jobs == $ENCOUNTERED_FAILURE) {
            print "\n\nError, $ENCOUNTERED_FAILURE jobs failed, but only have recorded $num_failed_jobs ... very strange and unexplained.\n\n";
            # I haven't seen this in my testing, but it's clear that others have, and I haven't figured out why or how yet...  bhaas
        }
        
		#把运行失败的命令全部写入一个文件，以后只需要单独运行这些命令，而不用重新运行全部命令
		my $failed_cmd_file = "failed_cmds.$$.txt";
		open (my $ofh, ">$failed_cmd_file") or die "Error, cannot write to $failed_cmd_file"; #最终会产生一个名为failed_cmds.$$.txt的文件，内容为所有失败了的命令
		@failed_jobs = sort {$a->{index}<=>$b->{index}} @failed_jobs;  #对其按index排序
        foreach my $failed_job (@failed_jobs) {
            print $ofh $failed_job->{cmd} . "\n";
        }      
		close $ofh;		
		print "\n\nSorry, $num_failed_jobs of $cmd_counter jobs failed.\n\n"
			. "Failed commands written to file: $failed_cmd_file\n\n";
		exit(1);
	}
}
#运行结束
print "all the files have been processed\n";

#################
##  子程序     ##
#################

sub run_cmd {
	my ($index, $cmd) = @_;
	print "\nRUNNING: $cmd\n";	
	#my $ret = system($cmd);		
	my $ret = &trim_fastq($cmd);
	if ($ret) {  #非零即为错误
		print STDERR "Error, command: $cmd died with ret $ret";
	}		
	open (my $log_fh, ">$log_dir/$index.ret") or die "Error, cannot write to log file for $index.ret"; #一个文件记录一个进程的运行结果
	print $log_fh $ret; #将调用外部命令结果'0'或'1'输出到日志文件
	close $log_fh;
	return($ret); #返回该命令运行情况
}


sub collect_jobs {
	my ($job_tracker_href, $failed_jobs_aref) = @_;
	my @job_indices = keys %$job_tracker_href;
	my $num_finished = 0;
	foreach my $index (@job_indices) {# 每次检测一个进程（job）	
		my $log_file = "$log_dir/$index.ret";	# 一个进程的运行结果对应一个文件
		if (-s $log_file) { # 如果log存在且大小不为零
			my $ret_val = `cat $log_file`; # 捕获文件内容
			chomp $ret_val; # 去除换行符
			my $job = $job_tracker_href->{$index};
			if ($ret_val == 0) {	#如果内容为字符'0'，进程成功结束
				print "SUCCESS[$index]: $job\n";				
			}
			else {#否则，进程运行失败，但是也处理完了
				print "FAILED[$index]: $job\n";
				$ENCOUNTERED_FAILURE++;   # 记录失败结束的进程数量
                push (@$failed_jobs_aref, {index => $index,
                                           cmd => $job_tracker_href->{$index},
                      });
			}			
			unlink $log_file;
			$num_finished++; # 记录已经完成的命令
            delete $job_tracker_href->{$index}; # 一旦完成，就不在track
		}
	}

	return($num_finished);
}
                               #
##处理fastq文件
sub trim_fastq{
	my $sample_info=shift;
    #原始adapter序列的前adapter_offset个bp，否则就用adapter全长用来匹配
	my ($basename,$adapter,$adapter_offset)=(split /\t/,$sample_info); #考虑到子函数需要使用，另外连个变量的声明放置前文，作为全局变量
	unless ($adapter&&$adapter_offset) {	#若没有这两个参数，则报错
		die $usage;
	}
	my $adapter_substr = substr($adapter, 0, $adapter_offset);#取出实际用于匹配的adapter部分，从第1个字符开始，共得到$adapter_offset个字符
	my $input_file =$basename.".$suffix";                  #输入文件的名称
	my $output_file1 =$basename.".trimmed".$distance;      #输出文件1的名称
    my $output_file2 =$basename.".unmatched".$distance;    #输出文件2的名称
	my $output_file3 =$basename.".null".$distance;      #输出文件3的名称
	
	my $raw_reads=0; 				#用于记录原始数据中的reads总数
	my $null_reads=0;				#记录整条读段都是接头的reads总数
	my $unmatched_reads=0;          #记录无法匹配3‘接头的reads总数
	my $trimmed_reads=0;            #记录trim掉3‘接头的reads总数，不含整条读段都是接头的情况
	my $cleaned_reads=0;            #trimmed_reads再去掉含有N和长度不足的读段后剩下的reads
	my $cleaned_length=0; 			#用于统计被截取读段被截取后的读段平均长度

	my $match_position;     #@match_result的第2个元素，barcode匹配到read上的的位置，
	my $id1;                #fastq文件中每个read的第1行
	my $DNAseq;             #fastq文件中每个read的第2行
	my $id2;                #fastq文件中每个read的第3行
	my $i = 0;              #用于读fastq文件循环内部，i表示fastq文件的第i行
	
    open(IN2, $input_file) || die "Can't open the fastq file\n";
	open(OUT1, ">$output_file1") || die "can't create $output_file1 $!\n";#文件句柄与文件名映射
	open(OUT2, ">$output_file2") || die "can't create $output_file2 $!\n";#文件句柄与文件名映射
	open(OUT3, ">$output_file3") || die "can't create $output_file3 $!\n";#文件句柄与文件名映射
	while(<IN2>){
		chomp;
		$i ++;
		if($i%4 == 1){    #如果当前行是ID行
			$id1 = $_;
			$raw_reads++; #原始数据中的reads总数增1
		}
		if($i%4 == 2){    #如果当前行是DNA序列,注意只有这里接受返回值
			$DNAseq = $_; #提取该DNA序列
			$match_position = adapter_match($DNAseq,$adapter_substr,$adapter_offset);#DNA序列与barcode序列匹配
		}
		if($i%4 == 3){    #如果当前行是另一个ID行
			$id2 = $_;
		}
		if($i%4 == 0){    #如果当前行是质量序列（4的整数倍），根据匹配结果，开始输出		  
			if ($match_position ==0){#表示整条DNA都是污染，保存到".null"文件
				$null_reads++;#整条读段都是接头的reads总数增1
				print OUT3 $id1."\n".$DNAseq."\n".$id2."\n".$_."\n";#输出整条序列（为了便于查看接头）
			}
			
			elsif($match_position ==length($DNAseq)){#没有找到匹配，保存到".unmatched"文件
				$unmatched_reads++;#无法匹配3‘接头的reads总数增1
				print OUT2 $id1."\n".$DNAseq."\n".$id2."\n".$_."\n";#输出整条序列
			}	
			
			else{#trim掉一部分，保存到".trimmed"文件
				my $trimmed_DNAseq = substr($DNAseq, 0, $match_position); #保留DNA序列上，barcode匹配点之前的部分
				#去除含N过量或者是过短的读段
				next if ($trimmed_DNAseq=~tr/Nn//>$max_N); #大于指定数量N,丢弃
				next if (length($trimmed_DNAseq)<$min_Len);#小于指定数量min_Len,丢弃
				
				$cleaned_reads++; #这里只记录符合条件的trimm掉3‘接头的reads总数
				$cleaned_length+=length($trimmed_DNAseq);#同时记录总bp数量
				
				my $trimmed_qual = substr($_, 0, $match_position);        #保留质量序列上，barcode匹配点之前的部分
				print OUT1 $id1."\n".$trimmed_DNAseq."\n".$id2."\n".$trimmed_qual."\n";#输出trimmed后剩下的序列			
				#my $pcr_primer = substr($DNAseq, $match_position, length($DNAseq)); #切掉的pcr_primer序列，用于检查，实际使用时要注释掉
				#print $pcr_primer."\n";#输出切掉的pcr_primer序列，用于检查，实际使用时要注释掉
			}		
		}#输出结束	
	}
	close(OUT1);
	close(OUT2);
	close(OUT3);
	close(IN2);
	
	$trimmed_reads=$raw_reads-$null_reads-$unmatched_reads;
	my $trimmed_ratio=sprintf ("%.4f",$trimmed_reads/$raw_reads)*100;
	my $raw_length=`head -n 2 $input_file|tail -n 1`; #用于储存原始读长(以第一个输入的第一个read长度作为读长)
	chomp $raw_length;
	$raw_length=length($raw_length);
    if($cleaned_reads>0)
	{$cleaned_length=sprintf ("%.2f",$cleaned_length/$cleaned_reads);}
	else{$cleaned_length="NA";}

	# 输出统计信息
	print $basename."\t".$raw_reads."\t".$raw_length."\t".$null_reads."\t".$unmatched_reads."\t".$trimmed_reads."\t".$trimmed_ratio."%\t".$cleaned_reads."\t".$cleaned_length."\n";	
	return 0;
}

sub adapter_match{
    # 每次只能考虑read第i个位置开始的固定长度的子序列，与adapter前12个bp（默认）匹配
	# 如果包括的接头小于这个长度就没法识别，会被当做不含接头的序列扔掉
	my $read_seq = shift;    #得到第1个参数，read序列
	my $adapter_seq = shift; #得到第2个参数，adapter序列
	my $adapter_offset=shift;
	my $read_len = length($read_seq);	
	my $position = $read_len;	#返回值初始值为全长，表示没有找到匹配
	my $min_offset=10;
 
	if($levenshtein==1){#如果采用levenshtein距离
		for(my $i = 0; $i< $read_len-$adapter_offset+1; $i++){#从5端开始，每次取$adapter_offset个bp与接头对比
			my $read_substr = substr($read_seq, $i, $adapter_offset);#检查过，没问题
			my $editDistance = levenshtein($read_substr,$adapter_seq);
			if ($editDistance <= $distance){
				$position=$i;  #记下这个位置，返回为了下一步trim
				last;          #找到了，就不继续找了，跳出循环	
			}				
		}			
	}
	else{#如果采用hamming距离
		for(my $i = 0; $i< $read_len-$min_offset+1; $i++){            
			my $read_substr = substr($read_seq, $i, $adapter_offset);#注意如果剩下的长度不够$adapter_offset，有多少截取多少而不报错
			my $editDistance = hamming($read_substr,$adapter_seq);#$read_substr有可能短于$adapter_offset(不影响结果)，短的必须在前面
			if ($editDistance <= $distance){				
				$position=$i;  #记下这个位置，返回为了下一步trim
				last;          #找到了，就不继续找了，跳出循环	
			}			
		}
	}		
	return $position;
}

###############################################
#    求2个字符串之间的levenshtein距离         #
###############################################
sub levenshtein
{
    my ($s1, $s2) = @_;
    my ($len1, $len2) = (length $s1, length $s2);
    return $len2 if ($len1 == 0);
    return $len1 if ($len2 == 0);
    my %mat;

    for (my $i = 0; $i <= $len1; ++$i)
    {
        for (my $j = 0; $j <= $len2; ++$j)
        {
            $mat{$i}{$j} = 0;
            $mat{0}{$j} = $j;
        }
        $mat{$i}{0} = $i;
    }

    my @ar1 = split(//, $s1);
    my @ar2 = split(//, $s2);

    for (my $i = 1; $i <= $len1; ++$i)
    {
        for (my $j = 1; $j <= $len2; ++$j)
        {
            my $cost = ($ar1[$i-1] eq $ar2[$j-1]) ? 0 : 1;
            $mat{$i}{$j} = min($mat{$i-1}{$j} + 1,
                                $mat{$i}{$j-1} + 1,
                                $mat{$i-1}{$j-1} + $cost);
        }
    }
    return $mat{$len1}{$len2};
}

sub min
{
    my @list = @_;
    my $min = $list[0];
    foreach my $i (@list)
    {
        $min = $i if ($i < $min);
    }
    return $min;
}
###########################################
#    求2个字符串之间的hamming距离         #
###########################################
sub hamming($$) { length( $_[ 0 ] ) - ( ( $_[ 0 ] ^ $_[ 1 ] ) =~ tr[\0][\0] ) }


