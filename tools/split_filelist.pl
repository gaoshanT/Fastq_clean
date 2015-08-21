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
##   ȫ�ֱ���  ##
#################
our $in;
our $out1;
our $out2;

#################
## �����������##
#################
&GetOptions( 'in=s' => \$in,
	'out1=s' => \$out1,
	'out2=s' => \$out2
	);

unless  ($in&&$out1&&$out2) {#��2����������ͨ������õ�
	die $usage;
}			 
#################
##  ������ʼ ##
#################
my $if_report = 0;
main: {
    open(IN, "$in");
	open(OUT1, ">$out1");
	open(OUT2, ">$out2");
        while (<IN>) {
		my $direction=(split)[0];
		if($direction=~/_1$/){  #����_1�ַ���ͳһ������������ļ�����
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