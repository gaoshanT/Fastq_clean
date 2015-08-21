#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
use File::Basename;
my $usage = <<_EOUSAGE_;

#########################################################################################
# bwa_remove.pl --file_list <FILE> --reference <FILE> 
#                 --max_dist[INT] --max_open [INT] --max_extension [INT] --len_seed [INT] --dist_seed [INT] --thread_num [INT]
#
# Required(2):
#  --file_list  The name of a txt file containing a list of input file names without any suffix
#  --reference  a fasta file containing the reference genome or transcriptom
#  
# BWA-related options(6):
#  --max_dist      Maximum edit distance [1]  
#  --max_open      Maximum number of gap opens [1]  
#  --max_extension Maximum number of gap extensions [1]  
#  --len_seed      Take the first INT subsequence as seed [15] 
#  --dist_seed     Maximum edit distance in the seed [1]  
#  --thread_num    Number of threads (multi-threading mode) [8] 
###########################################################################################

_EOUSAGE_
;

#################
##   ȫ�ֱ���  ##
#################
our $file_list;
our $reference;
our $index_name;
 
our $max_dist = 1;  #bwa��������༭���� 
our $max_open = 1;  #bwa��������gap����
our $max_extension = 1; #bwa��������gap����,-1��ʾ������gap
our $len_seed; #bwa�е�����������
our $dist_seed = 1; #bwa��������������༭����
our $thread_num = 8; #bwa������õ��߳����� 
################################
##   ��������Ŀ¼���ļ���·�� ##
################################
our $WORKING_DIR=cwd();#����Ŀ¼���ǵ�ǰĿ¼
our $DATABASE_DIR=$WORKING_DIR."/databases";#�������ݿ��ļ����ڵ�Ŀ¼
our $BIN_DIR=$WORKING_DIR."/bin";#���п�ִ���ļ����ڵ�Ŀ¼

##################
## ����������� ##
##################
&GetOptions( 'file_list=s' => \$file_list,#�������д�����������ļ����ƣ��޺�׺��
	'reference=s' => \$reference,#�ο��������ת¼����ļ����ƣ�FASTA��ʽ��
	'max_dist=i' => \$max_dist,
	'max_open=i' => \$max_open,
	'max_extension=i' => \$max_extension,
	'len_seed=i' => \$len_seed,
	'dist_seed=i' => \$dist_seed,			 
	'thread_num=i' => \$thread_num
			 );

unless ($file_list&&$reference) {
	die $usage;
}
$index_name = basename($reference);#
$index_name =~ s/\.\S*$//;#ȥ���ļ���׺��

#################
##  ������ʼ ##
#################
main: {
    #����bowtie-buildΪ�ο����н�������,���������usr/local/bin,���ڵ�ǰĿ¼�������"./"
	&process_cmd("$BIN_DIR/bwa index -p $DATABASE_DIR/$index_name -a bwtsw $reference") unless (-e "$DATABASE_DIR/$index_name.amb");
	my $sample;
	my $i=0;
    open(IN, "$file_list");
    while (<IN>) {
		$i=$i+1;
		chomp;
		my @return_col = split(/\t/, $_);#ÿ��ѭ������һ�У��������д���������ļ��������޺�׺����
		$sample=$return_col[0];#��1����sample���ƣ���2����adapterû�ã���Ҫ��Ϊ��ǰ������������Ҫ
		print "\n";
		print "#processing sample $i: $sample\n";
		#����ִ��command lines
		&process_cmd("$BIN_DIR/bwa aln -n $max_dist -o $max_open -e $max_extension -i 0 -l $len_seed -k $dist_seed -t $thread_num $DATABASE_DIR/$index_name $sample.clean > $sample.sai") unless (-s "$sample.sai");
		&process_cmd("$BIN_DIR/bwa samse -n 1 $DATABASE_DIR/$index_name $sample.sai $sample.clean > $sample.pre.sam") unless (-s "$sample.pre.sam");				
		&process_cmd("$BIN_DIR/SAM_filter_out_unmapped_reads.pl $sample.pre.sam $sample.unmapped $sample.mapped > $sample.sam") unless (-s "$sample.sam");
		system("rm $sample.sai");
		system("rm $sample.pre.sam");
		system("rm $sample.sam");
		system("rm $sample.mapped");
	}
	close(IN);
	print "###############################\n";
	print "All the samples have been processed by $0\n";
	}
####
sub process_cmd {
	my ($cmd) = @_;	
	print "CMD: $cmd\n";
	my $ret = system($cmd);	
	if ($ret) {
		die "Error, cmd: $cmd died with ret $ret";
	}
	return($ret);
}
