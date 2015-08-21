#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;

# ������;���Ӳ���fastq�ļ��еõ�barcode��Ϣ
# ע�⣬�����д�����䣬��˱�������֪��barcode�˹��˶�
my $usage = <<_EOUSAGE_;

#########################################################################################
# getBarcodes.pl --file_list <FILE>
#  --file_list The name of a txt file containing a list of input file names without any suffix
#  
###########################################################################################

_EOUSAGE_

	;
#################
##   ȫ�ֱ���  ##
#################
our $file_list;

#################
## �����������##
#################
&GetOptions( 'file_list=s' => \$file_list
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
		my $sample=$_; #ÿ��ѭ������һ�У��������д���������ļ��������޺�׺����
		my $fastq_head =  `head -n 1 $sample.fastq`;
		$fastq_head =~ /:([ATCG]+)$/; 
		print $sample."\t".$1."\n";
	}
        close(IN);
}