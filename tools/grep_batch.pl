#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
# grepbatch.pl --file_list <FILE> --barcode <FILE>
#  --file_list The name of a txt file containing a list of input file names without any suffix
#  
###########################################################################################

_EOUSAGE_

	;
#################
##   全局变量  ##
#################
our $file_list;
our $barcode;
#################
## 输入参数处理##
#################
&GetOptions( 'file_list=s' => \$file_list,
	'barcode=s' => \$barcode
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
		my $sample_file =$_.".fastq"; #每次循环读入一行，后续进行处理该样本文件（名称无后缀）。
		my $b_number =  `grep  $barcode $sample_file | wc -l`;
		print $b_number;
	}
        close(IN);
}