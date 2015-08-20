#!/usr/bin/perl
use strict;   #变量必须定义才可以使用
use warnings; #对未初始化变量是给出警告
use Getopt::Long; #这个模块可以接受完整参数

# 程序用途：从fastq文件中提取单侧测序文件

#参数处理
my $usage = <<_EOUSAGE_;

#########################################################################################
# getSingle.pl [--forward|--reverse] <FILE> 
#
# Options:
#  	--forward	extract forward reads with a suffix '/1', output to STDOUT
#  	--reverse	extract reverse reads with a suffix '/2', output to STDOUT
#  	--all		seperate forward and reverse reads into two file, default setting
#
##########################################################################################

_EOUSAGE_
	;
#################
##   全局变量  ##
#################
our $forward;
our $reverse;
our $all;

#################
## 输入参数处理##
#################
&GetOptions( 'forward' => \$forward,
			'reverse' => \$reverse,
			'all' => \$all,
			 );

my $file = shift;		# GetOptions后剩余参数作为文件名
	 
unless (-s $file) {
	die $usage;
}
if (!$forward&&!$reverse){$all=1;}

#################
##   主程序    ##
#################
&extracter($file,'/1') if $forward; #若设定，仅需将正向读段输出到STDOUT
&extracter($file,'/2') if $reverse; #若设定，仅需将反向读段输出到STDOUT
if ($all){							#若设定，将正反读段分别输出到文件
	open my $out1,'>','forward.fq';
	select($out1);
	&extracter($file,'/1');
	close $out1;
	open my $out2,'>','reverse.fq';
	select($out2);
	&extracter($file,'/2');
	close $out2;
}

#################
##   子程序    ##
#################
# 根据$suffix，从fastq格式文件中提取相应读段
sub extracter{
	my $file=shift;
	my $suffix=shift;
	open my $fh,'<',$file or die "can't open this file\n$usage\n$!";
	while(!eof($fh)){
		my $header=<$fh>;
		my $seq=<$fh>;
		my $symbol=<$fh>;
		my $quality=<$fh>;
		print "$header$seq$symbol$quality" if ($header=~/$suffix$/);
		}
	close $fh;
}		
