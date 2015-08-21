#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;

# ������;������grepͳ��fastq�ļ���adapter���ֵ�������������
# ������fastq_clean����
my $usage = <<_EOUSAGE_;

#########################################################################################
# $0 --file_list <FILE> --adapter  <String> --with_barcode
#  --file_list	The name of a txt file containing a list of input file names without any suffix
#  --adapter	The 3 end adaper sequence before the barcode
#  --with_barcode	concat the barcode sequence to check the adapters  [Not selected]
###########################################################################################

_EOUSAGE_

	;
#################
##   ȫ�ֱ���  ##
#################
our $file_list;	#�ļ����������У���1����sample���ƣ���2����barcode
our $adapter;
our $with_barcode;	#�Ƿ���adapter��������barcode

#################
## �����������##
#################
&GetOptions( 'file_list=s' => \$file_list,
	'adapter=s' => \$adapter,
	'with_barcode!' => \$with_barcode
	);

unless  ($file_list&&$adapter) {#��2����������ͨ������õ�
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
		my $sample=$cols[0];
		my $check_string;
		if($with_barcode){
			$check_string=$adapter.$cols[1]; 
		}
		else{
			$check_string=$adapter; 
		}
		my $hit_num =  `grep $check_string $sample.fastq | wc -l`;
		print $sample."\t".$hit_num;
	}
        close(IN);
}