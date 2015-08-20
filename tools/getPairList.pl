#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;

# 程序用途：根据filelist1.list得到配对文件名的列表
# 仅用于提取fastq_clean处理的双端测序文件中的配对读段
my $usage = <<_EOUSAGE_;

#########################################################################################
# getPairList.pl --in <FILE> --out  <FILE>
###########################################################################################

_EOUSAGE_

	;
#################
##   全局变量  ##
#################
our $in;
our $out;

#################
## 输入参数处理##
#################
&GetOptions( 'in=s' => \$in,
	'out=s' => \$out
	);

unless  ($in&&$out) {#这2个参数必须通过输入得到
	die $usage;
}			 
#################
##  主程序开始 ##
#################
main: {
	open(IN, "$in");
	open(OUT, ">$out");
    while (<IN>) {
		my @cols = split(/\t/, $_);
        my $col1=$cols[0];
		$col1 =~ s/_F$/_R/;
		print OUT  $cols[0]."\t".$col1."\n"; 
	}
	close(IN);
	close(OUT);
}