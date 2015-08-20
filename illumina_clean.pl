#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
#
# $0 ./conf/input.config
#
#  <input.config>  the configuration file containing all the parameters setting
#
#########################################################################################

_EOUSAGE_
	;
	
#################
##   全局变量  ##
#################
#默认参数都是针对illumina 100bp技术的，其他长度要注意重设参数
our $file_list;  #输入文件的列表，这里只有base name，后缀名必须是'.fastq'或'.fq'
our $run_R;
our $save_clean0;
our $primer_len=0;
our $rRNA_removal;
our $virus_removal;
our $rRNA_reference="rRNA.fasta";
our $virus_reference= "virus_genbank186.fasta";#病毒库（FASTA格式）
#去除low quality、adapter(可能含barcode)等片段
our $pattern_file;
our $quality_Cutoff=20;
our $region_5Len= 10;
our $region_3Len= 20;		#100bp测序用20bp
our $n_Cutoff=2;		#100bp测序不能超过2个N
our $adapter_mismatch=0.1;	#100bp以内0.1最合适
our $read_Length=25;        #数据clean后需要保留的最短的read
our $read_PerYield=5e5;#5Mreads*4*100=2G字节
#align到rRNA和病毒库的reads必须去除，都用下面同一组参数
our $max_dist = 4;  #bwa允许的最大编辑距离
our $max_open = 1;  #bwa允许的最大gap数量
our $max_extension = 1; #bwa允许的最大gap长度,-1表示不允许长gap
our $len_seed=50; #bwa中的种子区长度，100bp测序用50
our $dist_seed = 2; #bwa种子区允许的最大编辑距离
our $thread_num = 8; #bwa程序调用的线程数量

################################
##   设置所有目录和文件的路径 ##
################################
our $WORKING_DIR=cwd();#工作目录就是当前目录
our $DATABASE_DIR=$WORKING_DIR."/databases";#所有数据库文件所在的目录
our $BIN_DIR=$WORKING_DIR."/bin";#所有可执行文件所在的目录
our $CONF_DIR=$WORKING_DIR."/conf";#所有配置文件所在的目录

##################
## 程序参数处理 ##
##################
#  必须至少提供一个参数，才可以继续
die $usage unless (-s $ARGV[0]);
open CONF,'<',$ARGV[0] or die "Can't read configure file ".$ARGV[0]." :$!";
while(<CONF>){
    # 注释行与空行不处理
	next if (/^#/||/^\s*$/);
	# chomp可以同时去掉回车换行
	chomp;
	my ($option,$value)=split ('=',$_);
	die "$option has no value\n" if (($value eq '')||(!defined $value));
	if($option eq 'file_list'){$file_list=$value; print $value,"\n";}
		elsif($option eq 'run_R'){$run_R=$value}
		elsif($option eq 'save_clean0'){$save_clean0=$value}
		elsif($option eq 'primer_len'){$primer_len=$value}
		elsif($option eq 'rRNA_removal'){$rRNA_removal=$value}
		elsif($option eq 'rRNA_reference'){$rRNA_reference=$value}
		elsif($option eq 'virus_removal'){$virus_removal=$value}
		elsif($option eq 'virus_reference'){$virus_reference=$value}
		elsif($option eq 'pattern_file'){$pattern_file=$CONF_DIR."/".$value}
		elsif($option eq 'quality_Cutoff'){$quality_Cutoff=$value}
		elsif($option eq 'region_5Len'){$region_5Len=$value}
		elsif($option eq 'region_3Len'){$region_3Len=$value}
		elsif($option eq 'n_Cutoff'){$n_Cutoff=$value}
		elsif($option eq 'adapter_mismatch'){$adapter_mismatch=$value}
		elsif($option eq 'read_Length'){$read_Length=$value}
		elsif($option eq 'read_PerYield'){$read_PerYield=$value}
		elsif($option eq 'max_dist'){$max_dist=$value}
		elsif($option eq 'max_open'){$max_open=$value}
		elsif($option eq 'max_extension'){$max_extension=$value}
		elsif($option eq 'len_seed'){$len_seed=$value}
		elsif($option eq 'dist_seed'){$dist_seed=$value}
		elsif($option eq 'thread_num'){$thread_num=$value}
		else {die "Unknow Option: $_\n"}
}

unless (-s $file_list) {
	die $usage;
}

##############
##  主程序  ##
##############
main: {
	# 首先检查工作目录中是否含有所有输入数据文件，并且统一文件后缀名称为'.fastq'
    filelist_check($file_list);
	# 如果rna-seq中使用随机引物，切除5'端几个bp（等于随机引物长度）
	# 输入文件（原始数据）必须".fastq"后缀，输出文件（trim后数据）必须".fastq"后缀，原始数据保留为".raw"后缀
	if($primer_len){
		system("$BIN_DIR/trim_ends.pl --cmds_file $file_list --CPU $thread_num --end_len $primer_len");
		$region_5Len= 10 - $primer_len;
	}
    #先去除两端low-quality bases（<Q20），然后去除含有2个"N"以上的reads，再切除3'端adapter/PCR primer，最后去除短reads（<25bp）
	#输入文件必须".fastq"后缀，输出文件必须".clean"后缀
	if($run_R){
		system("Rscript $BIN_DIR/RNA-seq_clean_batch.R filelist=$file_list pattern=$pattern_file qualityCutoff=$quality_Cutoff region5Len=$region_5Len region3Len=$region_3Len nCutoff=$n_Cutoff adapterMismatch=$adapter_mismatch readLength=$read_Length RdPerYield=$read_PerYield");
 	}       
	#如果需要，就去除rRNA污染，输入文件必须是".clean"后缀
	if($rRNA_removal){	
		system("$BIN_DIR/bwa_remove.pl --file_list $file_list --reference $DATABASE_DIR/$rRNA_reference --max_dist $max_dist --max_open $max_open --max_extension $max_extension --len_seed $len_seed --dist_seed $dist_seed --thread_num $thread_num");
		#输出文件必须".clean"后缀
		system("$BIN_DIR/files_name_change.pl --file_list $file_list --suffix1 unmapped --suffix2 clean");
		if($save_clean0)
		#保留去除rRNA后文件结果为".clean0"后缀
		{system("$BIN_DIR/files_copy_batch.pl --file_list $file_list --suffix1 clean --suffix2 clean0");}
	}
	#如果需要，就去除virus污染，输入文件必须是".clean"后缀
	if($virus_removal){	
		system("$BIN_DIR/bwa_remove.pl --file_list $file_list --reference $DATABASE_DIR/$virus_reference --max_dist $max_dist --max_open $max_open --max_extension $max_extension --len_seed $len_seed --dist_seed $dist_seed --thread_num $thread_num");
		#输出文件必须".clean"后缀
		system("$BIN_DIR/files_name_change.pl --file_list $file_list --suffix1 unmapped --suffix2 clean");
	}
}

##############
##  子程序  ##
##############
sub filelist_check {
    my $list = shift;
	open(LIST, "$list");
	while(<LIST>){
		chomp;
		my @cols = split(/\t/, $_);
		my $file_name1=$cols[0].'.fastq'; #如果找到文件列表里面的文件（后缀名是'.fastq'）
		print $cols[0]."\n";
		unless(-s $file_name1){           #如果没有找到文件列表里面的文件（后缀名是'.fastq'）
			my $file_name2=$cols[0].'.raw'; #再找文件列表里面的文件（后缀名是'.fq'）
			unless (-s $file_name2){
				die "you must put the file $file_name1 in the $WORKING_DIR\n";
			}
			rename $file_name2,$file_name1;#要保证下一步输入文件后缀名必须是'.fastq'
		}
	}
	close(LIST);
}