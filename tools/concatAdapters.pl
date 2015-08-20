#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;

# 程序用途：根据adapter生成file list文件
# 仅用于fastq_clean流程
my $usage = <<_EOUSAGE_;

#########################################################################################
# $0 --file_list <FILE> --prefix  <String> --suffix  <String>  --with_barcode
#  --file_list The name of a txt file containing a list of input file names without any suffix
#  --with_barcode	concat the barcode sequence to check the adapters  [Not selected] 
###########################################################################################

_EOUSAGE_

	;
#################
##   全局变量  ##
#################
our $file_list;
our $prefix;
our $suffix;
our $with_barcode;	#是否在adapter后连接上barcode

#################
## 输入参数处理##
#################
&GetOptions( 'file_list=s' => \$file_list,
	'prefix=s' => \$prefix,
	'suffix=s' => \$suffix,
	'with_barcode!' => \$with_barcode
	);

unless  ($file_list&&$prefix) {#这2个参数必须通过输入得到
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
		if($with_barcode){
			print $cols[0]."\t".$prefix.$cols[1].$suffix."\n";
		}
		else{
			print $cols[0]."\t".$prefix."\n";		
		}
	}
        close(IN);
}