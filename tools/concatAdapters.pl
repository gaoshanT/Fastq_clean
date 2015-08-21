#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;

# ������;������adapter����file list�ļ�
# ������fastq_clean����
my $usage = <<_EOUSAGE_;

#########################################################################################
# $0 --file_list <FILE> --prefix  <String> --suffix  <String>  --with_barcode
#  --file_list The name of a txt file containing a list of input file names without any suffix
#  --with_barcode	concat the barcode sequence to check the adapters  [Not selected] 
###########################################################################################

_EOUSAGE_

	;
#################
##   ȫ�ֱ���  ##
#################
our $file_list;
our $prefix;
our $suffix;
our $with_barcode;	#�Ƿ���adapter��������barcode

#################
## �����������##
#################
&GetOptions( 'file_list=s' => \$file_list,
	'prefix=s' => \$prefix,
	'suffix=s' => \$suffix,
	'with_barcode!' => \$with_barcode
	);

unless  ($file_list&&$prefix) {#��2����������ͨ������õ�
	die $usage;
}			 
#################
##  ������ʼ ##
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