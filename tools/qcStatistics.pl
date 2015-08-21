#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
# qcStatistics.pl --file_list <FILE> --suffix [String] --quality_Cutoff [INT] --letter [String] --read_PerYield [FLOAT] 
#                                  
# Required(1):
#  --file_list  The name of a txt file containing a list of input file names without any suffix 
#
# Options(5):
#  --quality_Cutoff   Low quality bases below this parameter will be trimmed from both ends of reads [20]
#  --letter     [N] 
#  --read_PerYield    Number of reads in each iteration to limit the memory usage [5e5] 
###########################################################################################

_EOUSAGE_

	;

#################
##   ȫ�ֱ���  ##
#################
#Ĭ�ϲ����������illumina 100bp�����ģ���������Ҫע���������
our $file_list;
our $suffix = "fastq";
our $letter = "N";
our $quality_Cutoff=20;
our $read_PerYield=5e5;#5M reads*4*100=2G�ֽ�

################################
##   ��������Ŀ¼���ļ���·�� ##
################################
our $WORKING_DIR=cwd();#����Ŀ¼���ǵ�ǰĿ¼
our $DATABASE_DIR=$WORKING_DIR."/databases";#�������ݿ��ļ����ڵ�Ŀ¼
our $BIN_DIR=$WORKING_DIR."/tools";#���п�ִ���ļ����ڵ�Ŀ¼

##################
## ����������� ##
##################
&GetOptions( 'file_list=s' => \$file_list,#�������д�����������ļ����ƣ��޺�׺��
	'suffix=s' => \$suffix,
	'letter=s' => \$letter,	
	'quality_Cutoff=i' => \$quality_Cutoff,
	'read_PerYield=f' => \$read_PerYield
			 );

unless ($file_list) {
	die $usage;
}

#################
##  ������ʼ ##
################
main: {
	open(IN,$file_list) || die "Can't open the file $file_list\n";
	my $sample;
	my $i=0;
	
	while(<IN>){
		$i=$i+1;
		chomp;
		$sample=$_; 
		print "#processing sample $i by $0: $sample\n";
		my $input_file = $sample.".".$suffix;
		#print "Rscript $BIN_DIR/Fq_statistics.R fastqfile=$input_file letter=$letter qualityCutoff=$quality_Cutoff RdPerYield=$read_PerYield\n";
		system("Rscript $BIN_DIR/Fq_statistics.R fastqfile=$input_file letter=$letter qualityCutoff=$quality_Cutoff RdPerYield=$read_PerYield");  
	}	
}