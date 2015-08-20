#!/usr/bin/perl
#use strict;   #变量必须定义才可以使用
#use warnings; #对未初始化变量是给出警告
use Getopt::Long; #这个模块可以接受完整参数

#参数处理
my $usage = <<_EOUSAGE_;

#########################################################################################
# files_copy_batch.pl --file_list <FILE> --suffix1 <String> --suffix2 <String>
# Required:
#  --file_list       a file containing all fastq file name for processing
#  --suffix1
#  --suffix2
##########################################################################################

_EOUSAGE_
	;
#定义变量接受命令行参数	
our $file_list;        #包括需要处理的所有fastq文件名称列表
our $suffix1;        #
our $suffix2;  


#从命令行参数向变量传值
&GetOptions( 'file_list=s' => \$file_list,
	     'suffix1=s' => \$suffix1,
	     'suffix2=s' => \$suffix2
			 );

#主程序开始
my $sample;
open(IN1,$file_list) || die "Can't open the $file_list\n";
while(<IN1>){
	chomp;	
	my @return_col = split(/\t/, $_);#每次循环读入一行，后续进行处理该样本文件（名称无后缀）。
	$sample=$return_col[0];
	my $old_name= $sample.".$suffix1";
	my $new_name= $sample.".$suffix2";
	print "cp $old_name $new_name\n";
	my $result = `cp $old_name $new_name`;#文件拷贝
}
close(IN1);
