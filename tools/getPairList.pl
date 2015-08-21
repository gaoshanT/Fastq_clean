#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;

# ������;������filelist1.list�õ�����ļ������б�
# ��������ȡfastq_clean�����˫�˲����ļ��е���Զ���
my $usage = <<_EOUSAGE_;

#########################################################################################
# getPairList.pl --in <FILE> --out  <FILE>
###########################################################################################

_EOUSAGE_

	;
#################
##   ȫ�ֱ���  ##
#################
our $in;
our $out;

#################
## �����������##
#################
&GetOptions( 'in=s' => \$in,
	'out=s' => \$out
	);

unless  ($in&&$out) {#��2����������ͨ������õ�
	die $usage;
}			 
#################
##  ������ʼ ##
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