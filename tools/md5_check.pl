#!/usr/bin/env perl
use strict;
use warnings;
# 程序用途：检查md5码，同时完成文件改名（批处理）

my $usage = <<_EOUSAGE_;

#########################################################################################
# $0 <file_list> --no_check
#  <file_list>  the list of files
#  no_check donot check the files by md5
###########################################################################################

_EOUSAGE_
;
##################
## 程序参数处理 ##
##################
my $filelist=shift;  #第1列是旧文件名，第2列是新文件名
my $if_check=shift;  #是否做md5检查
unless (-s $filelist) {
	die $usage;
}

##############
##  主程序  ##
##############
main: {
	open LIST,'<',$filelist or die "Can't open the file $filelist:$!";
	while (<LIST>){
		chomp;
		my ($oldname,$newname)=(split(/\s+/,$_));
		file_check($oldname,$newname);
	}
	close (LIST);
}
print "all files passed the md5 check\n";
##############
##  子程序  ##
##############

#查看文件是否存在并重命名
sub file_check{
	my $oldname=shift;
	my $newname=shift;
	my $file_name=$oldname.'.fastq.gz';
	unless(-s $file_name){
			$file_name=$oldname.'.fq.gz';
			unless (-s $file_name){
				die "you must put the file $oldname.fastq.gz in the working directory\n";
			}
		}
	if(!$if_check) {&checkmd5($file_name)};
	rename $file_name, $newname.'.fastq.gz';# 文件重新命名
}

#查看文件md5是否正确
sub checkmd5 {
	my $file= shift;
	my $md_filename=$file.'.md5';
	open MD5,'<',$md_filename or die "Can't find the md5 file $md_filename";
	chomp(my $md5_file=<MD5>);
	$md5_file=~s/^(\S+)\s+\S+/$1/;
	chomp(my $md5_check=`md5sum $file`);
	$md5_check=~s/^(\S+)\s+\S+/$1/;
	if ($md5_check ne $md5_file){
		die "$file can't pass the md5 check\n";
	}
	close(MD5);
}
