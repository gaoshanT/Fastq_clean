#!/usr/bin/perl
#use strict;   #�������붨��ſ���ʹ��
#use warnings; #��δ��ʼ�������Ǹ�������
use Getopt::Long; #���ģ����Խ�����������

# ������;���ϲ�������׺��һ���ĳ�������trinity��װ

my $usage = <<_EOUSAGE_;

#########################################################################################
# files_combine.pl --filelist <FILE> --suffix <String> --output <FILE> 
# Required:
#  --filelist       a fastq file name without suffix for processing 
#  --suffix
##########################################################################################

_EOUSAGE_
	;
#################
##   ȫ�ֱ���  ##
#################
our $filelist;      #������Ҫ���������fastq�ļ������б�
our $suffix;        #
our $output; 

#################
## �����������##
#################
&GetOptions( 'filelist=s' => \$filelist,
	     'suffix=s' => \$suffix,
	     'output=s' => \$output
			 );

#################
##  ������ʼ ##
#################
open(IN1,$filelist) || die "Can't open the $filelist file\n";
my $files="";
while(<IN1>){
	chomp;
	my @cols = split(/\t/, $_);
	my $sample = $cols[0];#ÿ��ѭ������һ�У��������붼�Ǵ���������ļ��������޺�׺����
	my $inputfile=$sample.".".$suffix;
	$files=$files." ".$inputfile;
}
close(IN1);
&process_cmd("cat $files > $output");

############
#  �ӳ���  #
############
sub process_cmd {
	my ($cmd) = @_;	
	print "CMD: $cmd\n";
	my $ret = system($cmd);	
	if ($ret) {
		die "Error, cmd: $cmd died with ret $ret";
	}
	return($ret);
}