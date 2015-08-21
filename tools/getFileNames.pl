#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
# ������;���õ�һ��Ŀ¼������fastq�ļ����б�

my $usage = <<_EOUSAGE_;

#########################################################################################
# getFileNames.pl --dir <DIR>
#  --file_list The name of a txt file containing a list of input file names without any suffix
#  
###########################################################################################

_EOUSAGE_

	;

################################
##   ��������Ŀ¼���ļ���·�� ##
################################
our $WORKING_DIR;#����Ŀ¼���ǵ�ǰĿ¼
our $dir;
#################
## �����������##
#################
&GetOptions( 'dir=s' => \$dir
			 );

if($dir){
	$WORKING_DIR=cwd().$dir;
}
else{
	$WORKING_DIR=".";
}			 
#################
##  ������ʼ ##
#################
main: {
opendir(DIR, $WORKING_DIR) || die "Can't open directory $WORKING_DIR";
my @files = readdir(DIR);
@files = sort { $a cmp $b } @files; #������ĸ����
foreach (@files){#���е��ļ�������Ŀ¼
	if (/(\S+).fastq$/) {print $1."\n";}
}
closedir DIR; 
}