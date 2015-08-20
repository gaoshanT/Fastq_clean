#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
use File::Basename;
my $usage = <<_EOUSAGE_;

#########################################################################################
# bwa_remove.pl --file_list <FILE> --reference <FILE> 
#                 --max_dist[INT] --max_open [INT] --max_extension [INT] --len_seed [INT] --dist_seed [INT] --thread_num [INT]
#
# Required(2):
#  --file_list  The name of a txt file containing a list of input file names without any suffix
#  --reference  a fasta file containing the reference genome or transcriptom
#  
# BWA-related options(6):
#  --max_dist      Maximum edit distance [1]  
#  --max_open      Maximum number of gap opens [1]  
#  --max_extension Maximum number of gap extensions [1]  
#  --len_seed      Take the first INT subsequence as seed [15] 
#  --dist_seed     Maximum edit distance in the seed [1]  
#  --thread_num    Number of threads (multi-threading mode) [8] 
###########################################################################################

_EOUSAGE_
;

#################
##   全局变量  ##
#################
our $file_list;
our $reference;
our $index_name;
 
our $max_dist = 1;  #bwa允许的最大编辑距离 
our $max_open = 1;  #bwa允许的最大gap数量
our $max_extension = 1; #bwa允许的最大gap长度,-1表示不允许长gap
our $len_seed; #bwa中的种子区长度
our $dist_seed = 1; #bwa种子区允许的最大编辑距离
our $thread_num = 8; #bwa程序调用的线程数量 
################################
##   设置所有目录和文件的路径 ##
################################
our $WORKING_DIR=cwd();#工作目录就是当前目录
our $DATABASE_DIR=$WORKING_DIR."/databases";#所有数据库文件所在的目录
our $BIN_DIR=$WORKING_DIR."/bin";#所有可执行文件所在的目录

##################
## 程序参数处理 ##
##################
&GetOptions( 'file_list=s' => \$file_list,#包括所有待处理的样本文件名称（无后缀）
	'reference=s' => \$reference,#参考基因组或转录组的文件名称（FASTA格式）
	'max_dist=i' => \$max_dist,
	'max_open=i' => \$max_open,
	'max_extension=i' => \$max_extension,
	'len_seed=i' => \$len_seed,
	'dist_seed=i' => \$dist_seed,			 
	'thread_num=i' => \$thread_num
			 );

unless ($file_list&&$reference) {
	die $usage;
}
$index_name = basename($reference);#
$index_name =~ s/\.\S*$//;#去掉文件后缀名

#################
##  主程序开始 ##
#################
main: {
    #调用bowtie-build为参考序列建立索引,如果程序不在usr/local/bin,而在当前目录，必须加"./"
	&process_cmd("$BIN_DIR/bwa index -p $DATABASE_DIR/$index_name -a bwtsw $reference") unless (-e "$DATABASE_DIR/$index_name.amb");
	my $sample;
	my $i=0;
    open(IN, "$file_list");
    while (<IN>) {
		$i=$i+1;
		chomp;
		my @return_col = split(/\t/, $_);#每次循环读入一行，后续进行处理该样本文件（名称无后缀）。
		$sample=$return_col[0];#第1列是sample名称，第2列是adapter没用，主要是为了前面程序的输入需要
		print "\n";
		print "#processing sample $i: $sample\n";
		#下面执行command lines
		&process_cmd("$BIN_DIR/bwa aln -n $max_dist -o $max_open -e $max_extension -i 0 -l $len_seed -k $dist_seed -t $thread_num $DATABASE_DIR/$index_name $sample.clean > $sample.sai") unless (-s "$sample.sai");
		&process_cmd("$BIN_DIR/bwa samse -n 1 $DATABASE_DIR/$index_name $sample.sai $sample.clean > $sample.pre.sam") unless (-s "$sample.pre.sam");				
		&process_cmd("$BIN_DIR/SAM_filter_out_unmapped_reads.pl $sample.pre.sam $sample.unmapped $sample.mapped > $sample.sam") unless (-s "$sample.sam");
		system("rm $sample.sai");
		system("rm $sample.pre.sam");
		system("rm $sample.sam");
		system("rm $sample.mapped");
	}
	close(IN);
	print "###############################\n";
	print "All the samples have been processed by $0\n";
	}
####
sub process_cmd {
	my ($cmd) = @_;	
	print "CMD: $cmd\n";
	my $ret = system($cmd);	
	if ($ret) {
		die "Error, cmd: $cmd died with ret $ret";
	}
	return($ret);
}
