#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;

# 程序用途：调用grep统计fastq文件中adapter出现的行数（批处理）
# 仅用于fastq_clean流程
my $usage = <<_EOUSAGE_;

#########################################################################################
# $0 --file_list <FILE> --adapter  <String> --with_barcode
#  --file_list	The name of a txt file containing a list of input file names without any suffix
#  --adapter	The 3 end adaper sequence before the barcode
#  --with_barcode	concat the barcode sequence to check the adapters  [Not selected]
###########################################################################################

_EOUSAGE_

	;
#################
##   全局变量  ##
#################
our $file_list;	#文件必须有两列，第1列是sample名称，第2列是barcode
our $adapter;
our $with_barcode;	#是否在adapter后连接上barcode

#################
## 输入参数处理##
#################
&GetOptions( 'file_list=s' => \$file_list,
	'adapter=s' => \$adapter,
	'with_barcode!' => \$with_barcode
	);

unless  ($file_list&&$adapter) {#这2个参数必须通过输入得到
	die $usage;
}			 
#################
##  主程序开始 ##
#################
main: {
        open(IN, "$file_list");
        while (<IN>) {
		chomp;
		my @cols = split(/\t/, $_);
		my $sample=$cols[0];
		my $check_string;
		if($with_barcode){
			$check_string=$adapter.$cols[1]; 
		}
		else{
			$check_string=$adapter; 
		}
		my $hit_num =  `grep $check_string $sample.fastq | wc -l`;
		print $sample."\t".$hit_num;
	}
        close(IN);
}