#!/usr/bin/perl
#use strict;   #变量必须定义才可以使用
#use warnings; #对未初始化变量是给出警告
use Getopt::Long; #这个模块可以接受完整参数

# 程序用途：得到每一个读段的长度

my $usage = <<_EOUSAGE_;

#########################################################################################
# $0 --file <FILE>
# Required:
#  --file       a file containing all fastq file name for processing without suffix
##########################################################################################

_EOUSAGE_
	;
#################
##   全局变量  ##
#################
our $file;        #指定fastq文件


#################
## 输入参数处理##
#################
&GetOptions( 'file=s' => \$file
			 );
unless ($file) {
	die $usage;
}

#################
##  主程序开始 ##
#################
my $i=0;
open(IN,$file) || die "Can't open the FASTQ file\n";
while(<IN>){
	chomp;
	$i++;
	if($i%4 == 2){    #如果当前行是DNA序列行
		print length($_)."\n";
	}
}
close(IN);
