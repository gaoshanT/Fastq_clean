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
##   设置所有目录和文件的路径 ##
################################
our $WORKING_DIR=cwd();#工作目录就是当前目录
our $DATABASE_DIR=$WORKING_DIR."/databases";#所有数据库文件所在的目录
our $BIN_DIR=$WORKING_DIR."/bin";#所有可执行文件所在的目录
our $Tools=$WORKING_DIR."/tools";#所有作为工具的可执行文件所在的目录
our $file_list;
our $image_type = "pdf";
our $suffix = "clean";
#################
## 输入参数处理##
#################
&GetOptions( 'file_list=s' => \$file_list,
		 'image_type=s' => \$image_type,
		 'suffix=s' => \$suffix
			 );

unless ($file_list) {#至少需要1个参数
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