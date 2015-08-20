#!/usr/bin/perl
#use strict;   #变量必须定义才可以使用
#use warnings; #对未初始化变量是给出警告
use Getopt::Long; #这个模块可以接受完整参数

# 程序用途：合并几个后缀名一样的程序，用于trinity组装

my $usage = <<_EOUSAGE_;

#########################################################################################
# files_combine.pl --filelist <FILE> --suffix <String> --output <FILE> 
# Required:
#  --filelist       a fastq file name without suffix for processing 
#  --suffix
##########################################################################################

_EOUSAGE_
	;
#################
##   全局变量  ##
#################
our $filelist;      #包括需要处理的所有fastq文件名称列表
our $suffix;        #
our $output; 

#################
## 输入参数处理##
#################
&GetOptions( 'filelist=s' => \$filelist,
	     'suffix=s' => \$suffix,
	     'output=s' => \$output
			 );

#################
##  主程序开始 ##
#################
open(IN1,$filelist) || die "Can't open the $filelist file\n";
my $files="";
while(<IN1>){
	chomp;
	my @cols = split(/\t/, $_);
	my $sample = $cols[0];#每次循环读入一行，后续代码都是处理该样本文件（名称无后缀）。
	my $inputfile=$sample.".".$suffix;
	$files=$files." ".$inputfile;
}
close(IN1);
&process_cmd("cat $files > $output");

############
#  子程序  #
############
sub process_cmd {
	my ($cmd) = @_;	
	print "CMD: $cmd\n";
	my $ret = system($cmd);	
	if ($ret) {
		die "Error, cmd: $cmd died with ret $ret";
	}
	return($ret);
}