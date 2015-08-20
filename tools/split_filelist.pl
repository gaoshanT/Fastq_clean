#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
# split_filelist.pl --in <FILE> --out1  <FILE> --out1  <FILE>
###########################################################################################

_EOUSAGE_

	;
#################
##   全局变量  ##
#################
our $in;
our $out1;
our $out2;

#################
## 输入参数处理##
#################
&GetOptions( 'in=s' => \$in,
	'out1=s' => \$out1,
	'out2=s' => \$out2
	);

unless  ($in&&$out1&&$out2) {#这2个参数必须通过输入得到
	die $usage;
}			 
#################
##  主程序开始 ##
#################
my $if_report = 0;
main: {
    open(IN, "$in");
	open(OUT1, ">$out1");
	open(OUT2, ">$out2");
        while (<IN>) {
		my $direction=(split)[0];
		if($direction=~/_1$/){  #带有_1字符的统一放入正向测序文件名单
			print OUT1 $_;
			$if_report = $if_report + 1;
		}
		else{
			print OUT2 $_;	
		}
	}
	close(IN);
	close(OUT1);
	close(OUT2);
	if($if_report==0){
			print "Error: to automatically produce file list,\n";
			print "the names of data files should have the suffix _1 and _2";			
		}
}