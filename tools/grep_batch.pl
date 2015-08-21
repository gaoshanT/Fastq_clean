#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
# grepbatch.pl --file_list <FILE> --barcode <FILE>
#  --file_list The name of a txt file containing a list of input file names without any suffix
#  
###########################################################################################

_EOUSAGE_

	;
#################
##   ȫ�ֱ���  ##
#################
our $file_list;
our $barcode;
#################
## �����������##
#################
&GetOptions( 'file_list=s' => \$file_list,
	'barcode=s' => \$barcode
			 );

unless ($file_list) {
	die $usage;
}			 
#################
##  ������ʼ ##
#################
main: {
        open(IN, "$file_list");
        while (<IN>) {
		chomp;
		my $sample_file =$_.".fastq"; #ÿ��ѭ������һ�У��������д���������ļ��������޺�׺����
		my $b_number =  `grep  $barcode $sample_file | wc -l`;
		print $b_number;
	}
        close(IN);
}