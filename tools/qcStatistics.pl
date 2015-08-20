#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
# qcStatistics.pl --file_list <FILE> --suffix [String] --quality_Cutoff [INT] --letter [String] --read_PerYield [FLOAT] 
#                                  
# Required(1):
#  --file_list  The name of a txt file containing a list of input file names without any suffix 
#
# Options(5):
#  --quality_Cutoff   Low quality bases below this parameter will be trimmed from both ends of reads [20]
#  --letter     [N] 
#  --read_PerYield    Number of reads in each iteration to limit the memory usage [5e5] 
###########################################################################################

_EOUSAGE_

	;

#################
##   全局变量  ##
#################
#默认参数都是针对illumina 100bp技术的，其他长度要注意重设参数
our $file_list;
our $suffix = "fastq";
our $letter = "N";
our $quality_Cutoff=20;
our $read_PerYield=5e5;#5M reads*4*100=2G字节

################################
##   设置所有目录和文件的路径 ##
################################
our $WORKING_DIR=cwd();#工作目录就是当前目录
our $DATABASE_DIR=$WORKING_DIR."/databases";#所有数据库文件所在的目录
our $BIN_DIR=$WORKING_DIR."/tools";#所有可执行文件所在的目录

##################
## 程序参数处理 ##
##################
&GetOptions( 'file_list=s' => \$file_list,#包括所有待处理的样本文件名称（无后缀）
	'suffix=s' => \$suffix,
	'letter=s' => \$letter,	
	'quality_Cutoff=i' => \$quality_Cutoff,
	'read_PerYield=f' => \$read_PerYield
			 );

unless ($file_list) {
	die $usage;
}

#################
##  主程序开始 ##
################
main: {
	open(IN,$file_list) || die "Can't open the file $file_list\n";
	my $sample;
	my $i=0;
	
	while(<IN>){
		$i=$i+1;
		chomp;
		$sample=$_; 
		print "#processing sample $i by $0: $sample\n";
		my $input_file = $sample.".".$suffix;
		#print "Rscript $BIN_DIR/Fq_statistics.R fastqfile=$input_file letter=$letter qualityCutoff=$quality_Cutoff RdPerYield=$read_PerYield\n";
		system("Rscript $BIN_DIR/Fq_statistics.R fastqfile=$input_file letter=$letter qualityCutoff=$quality_Cutoff RdPerYield=$read_PerYield");  
	}	
}