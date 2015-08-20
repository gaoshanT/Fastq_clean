#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Getopt::Long;
use List::Util;
use Cwd;
my $usage = <<_EOUSAGE_;

#################################################################################
# $0 --file_list <String> --suffix [String] --CPU [Int]
#  --file_list	a file containing a list of sra file without suffix(one SRA number per line)
#  --suffix suffix of the files     
#  --CPU	Default: 8
###################################################################################

_EOUSAGE_
	;

#################
##   全局变量  ##
#################
my $file_list = "";
my $suffix="";
my $CPU = 8;
my $ENCOUNTERED_FAILURE = 0; #全局变量，子程序中继承
#################
## 输入参数处理##
#################
&GetOptions (
			"file_list=s" => \$file_list,#需要执行的命令所在的文件
			"suffix=s" => \$suffix, #文件后缀名
			"CPU=i" => \$CPU,    #分配的CPU数量
             );

unless (-s $file_list && $suffix) {
	die $usage;
}

# 建立日志目录，日志文件保存cmd运行结果。进程间通讯用文件的缺点是，如果用户没有写权限的话，则不能运行
my $log_dir = "cmds_log.$$";
mkdir($log_dir) or die "Error, cannot mkdir $log_dir";

################################
##   设置所有目录和文件的路径 ##
################################
our $WORKING_DIR=cwd();#工作目录就是当前目录
our $BIN_DIR=$WORKING_DIR."/tools";#所有可执行文件所在的目录


#################
##  主程序开始 ##
#################
main: {
	my %job_tracker;		# 记录需要跟踪的命令总数
	my @failed_jobs;		# 记录失败的任务
	my $num_running = 0;	
    my @unix_cmds;  #这个数组记录所有的命令行
	
    #从文件中逐行读入命令行	
	open (my $fh, $file_list) or die "Error, cannot open file $file_list";      
	while (<$fh>) {
		chomp; #这个还是去除一下换行符号，如果只有一列，$cols[0]中还会有换行符
		my @cols = split(/\t/, $_);
		my $cmd;
		$cmd="gzip $cols[0].$suffix"; #这个是实际调用的程序
		push (@unix_cmds, $cmd);#用一个数组存储所有命令
	}
	close $fh;
	
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


#################
##  子程序     ##
#################

sub run_cmd {
	my ($index, $cmd) = @_;
	print "\nRUNNING: $cmd\n";	
	my $ret = system($cmd);		
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

