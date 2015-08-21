#!/usr/bin/perl -w 
use strict; 

if (@ARGV < 1)
{
  print "usage: $0 folder [R]\n";
  print " Given Arg 'R' , the script will recrusively modify all the file in the subdirectories under the specific folder\n";
  exit(0);
}

# ȥ��ָ��Ŀ¼�к��е�perl�ļ��еĻس���'\r'
# �Ӳ���R���Ա���������Ŀ¼
my $dir = shift;
if (@ARGV and $ARGV[0]=~/R/){
	&remove_r($dir,'R');
}else{
	&remove_r($dir,'F');
}

sub remove_r {
	my $dir=shift;
	my $flag=shift;
	#���ڱ�����������Ŀ¼������
	my @temp_dir;	
	opendir(DIR, $dir) || die "Can't open directory $dir";
	my @files = readdir(DIR);
	@files=map {$dir.'/'.$_} @files;
	foreach (@files){#���е��ļ�������Ŀ¼
		#Ӧ�ú��Զ�ȡ���ĵ�ǰ����һ��Ŀ¼
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



