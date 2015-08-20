#!/usr/bin/perl -w 
use strict; 

if (@ARGV < 1)
{
  print "usage: $0 folder [R]\n";
  print " Given Arg 'R' , the script will recrusively modify all the file in the subdirectories under the specific folder\n";
  exit(0);
}

# 去除指定目录中含有的perl文件中的回车符'\r'
# 加参数R可以遍历所有子目录
my $dir = shift;
if (@ARGV and $ARGV[0]=~/R/){
	&remove_r($dir,'R');
}else{
	&remove_r($dir,'F');
}

sub remove_r {
	my $dir=shift;
	my $flag=shift;
	#用于遍历子所有子目录的数组
	my @temp_dir;	
	opendir(DIR, $dir) || die "Can't open directory $dir";
	my @files = readdir(DIR);
	@files=map {$dir.'/'.$_} @files;
	foreach (@files){#所有的文件或者子目录
		#应该忽略读取到的当前和上一层目录
		#print $_,"\n";
		next if /\.$/;
		if ($flag=~/R/){
			if(-d $_){
				push @temp_dir,$_;
				next;
			}
		}
		if (/.pl$/){
			my $input=$_;
			my $output=$_;
			$output =~ s/.pl/.pl1/;
			print "Processing File: ",$_."\n";
			open(IN1,"<",$_) || die "Can't open the $_ file\n";
			open(OUT,">",$output) or die "Can't create the $_ file\n";
			while(<IN1>){
				$_=~ s/\r?\n/\n/; 
				print OUT $_;
			}
			close(OUT);
			close(IN1);
			system("mv $output $input");
		}
	}
	closedir DIR;
	if(@temp_dir){
		#@temp_dir=map {$dir.'/'.$_} @temp_dir;
		for(@temp_dir){
			print "Processing Directory: ",$_,"\n";
			&remove_r($_,'R');			
		}
	}
}



