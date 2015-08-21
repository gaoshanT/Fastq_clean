#!/usr/bin/perl
#use strict;   #�������붨��ſ���ʹ��
#use warnings; #��δ��ʼ�������Ǹ�������
use Getopt::Long; #���ģ����Խ�����������

#��������
my $usage = <<_EOUSAGE_;

#########################################################################################
# files_name_change.pl --file_list <FILE> --suffix1 <String> --suffix2 <String>
# Required:
#  --file_list       a file containing all fastq file name for processing
#  --suffix1
#  --suffix2
##########################################################################################

_EOUSAGE_
	;
#����������������в���	
our $file_list;        #������Ҫ���������fastq�ļ������б�
our $suffix1;        #
our $suffix2;  


#�������в����������ֵ
&GetOptions( 'file_list=s' => \$file_list,
	     'suffix1=s' => \$suffix1,
	     'suffix2=s' => \$suffix2
			 );

#������ʼ
my $sample;
open(IN1,$file_list) || die "Can't open the $file_list\n";
while(<IN1>){
	chomp;	
	my @return_col = split(/\t/, $_);#ÿ��ѭ������һ�У��������д���������ļ��������޺�׺����
	$sample=$return_col[0];
	my $old_name= $sample.".$suffix1";
	my $new_name= $sample.".$suffix2";
	print "mv $old_name $new_name\n";
	my $result = `mv $old_name $new_name`;#�õ��ļ�$file������;	
}
close(IN1);
