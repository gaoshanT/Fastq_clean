#!/usr/bin/perl
use strict;
use warnings;
use IO::File;
use Getopt::Long;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
# sRNA_len_dist_batch.pl --file_list <FILE> --image_type [String] --suffix [String]
#                                  
# Required(1):
#  --file_list The name of a txt file containing a list of input file names without any suffix
# Options(2):
#  --image_type The output image type of the small RNA length distribution plot [jpg]
#  --suffix the suffix file name of the sample [clean]
###########################################################################################

_EOUSAGE_
	;
################################
##   ��������Ŀ¼���ļ���·�� ##
################################
our $WORKING_DIR=cwd();#����Ŀ¼���ǵ�ǰĿ¼
our $DATABASE_DIR=$WORKING_DIR."/databases";#�������ݿ��ļ����ڵ�Ŀ¼
our $BIN_DIR=$WORKING_DIR."/bin";#���п�ִ���ļ����ڵ�Ŀ¼
our $Tools=$WORKING_DIR."/tools";#������Ϊ���ߵĿ�ִ���ļ����ڵ�Ŀ¼
our $file_list;
our $image_type = "pdf";
our $suffix = "clean";
#################
## �����������##
#################
&GetOptions( 'file_list=s' => \$file_list,
		 'image_type=s' => \$image_type,
		 'suffix=s' => \$suffix
			 );

unless ($file_list) {#������Ҫ1������
	die $usage;
}

system("mkdir dist_plots");
my $fh = IO::File->new($file_list) || die "Can not open the file $file_list $!\n";
while(<$fh>)
{
	chomp;
	my $sample = $_;
	system("$Tools/sRNA_len_dist.pl --sample $sample --image_type $image_type --suffix $suffix");
	system("mv $sample.pdf ./dist_plots");
	system("mv $sample.table ./dist_plots");
}
$fh->close;