#!/usr/bin/perl
#use strict;   #�������붨��ſ���ʹ��
#use warnings; #��δ��ʼ�������Ǹ�������
use Getopt::Long; #���ģ����Խ�����������

# ������;���õ�ÿһ�����εĳ���

my $usage = <<_EOUSAGE_;

#########################################################################################
# $0 --file <FILE>
# Required:
#  --file       a file containing all fastq file name for processing without suffix
##########################################################################################

_EOUSAGE_
	;
#################
##   ȫ�ֱ���  ##
#################
our $file;        #ָ��fastq�ļ�


#################
## �����������##
#################
&GetOptions( 'file=s' => \$file
			 );
unless ($file) {
	die $usage;
}

#################
##  ������ʼ ##
#################
my $i=0;
open(IN,$file) || die "Can't open the FASTQ file\n";
while(<IN>){
	chomp;
	$i++;
	if($i%4 == 2){    #�����ǰ����DNA������
		print length($_)."\n";
	}
}
close(IN);
