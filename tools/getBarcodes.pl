#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;

# 程序用途：从测序fastq文件中得到barcode信息
# 注意，由于有错误分配，因此必须与已知的barcode人工核对
my $usage = <<_EOUSAGE_;

#########################################################################################
# getBarcodes.pl --file_list <FILE>
#  --file_list The name of a txt file containing a list of input file names without any suffix
#  
###########################################################################################

_EOUSAGE_

	;
#################
##   全局变量  ##
#################
our $file_list;

#################
## 输入参数处理##
#################
&GetOptions( 'file_list=s' => \$file_list
			 );

unless ($file_list) {
	die $usage;
}			 
#################
##  主程序开始 ##
#################
main: {
        open(IN, "$file_list");
        while (<IN>) {
		chomp;
		my $sample=$_; #每次循环读入一行，后续进行处理该样本文件（名称无后缀）。
		my $fastq_head =  `head -n 1 $sample.fastq`;
		$fastq_head =~ /:([ATCG]+)$/; 
		print $sample."\t".$1."\n";
	}
        close(IN);
}