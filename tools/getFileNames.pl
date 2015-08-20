#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Cwd;
# 程序用途：得到一个目录内所有fastq文件的列表

my $usage = <<_EOUSAGE_;

#########################################################################################
# getFileNames.pl --dir <DIR>
#  --file_list The name of a txt file containing a list of input file names without any suffix
#  
###########################################################################################

_EOUSAGE_

	;

################################
##   设置所有目录和文件的路径 ##
################################
our $WORKING_DIR;#工作目录就是当前目录
our $dir;
#################
## 输入参数处理##
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
##  主程序开始 ##
#################
main: {
opendir(DIR, $WORKING_DIR) || die "Can't open directory $WORKING_DIR";
my @files = readdir(DIR);
@files = sort { $a cmp $b } @files; #根据字母排序
foreach (@files){#所有的文件或者子目录
	if (/(\S+).fastq$/) {print $1."\n";}
}
closedir DIR; 
}