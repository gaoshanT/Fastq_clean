#!/usr/bin/perl
use strict;

# 程序用途：统计一个fastq文件中
# 仅用于fastq_clean流程Q20碱基（Q >= 20）的比例

my $file = $ARGV[0] or die "Usage: $0 input > output\n";;

#################
##  主程序开始 ##
#################
open IN,"<$file" or die "File $file not found error here\n";
my $position;
my %count;	#统计每列碱基总数
my %count_Q;	#统计每列Q20总数
my @key;
my $line = 0;
while(<IN>){
	chomp;              #每读入一行，就先去掉回车
	$line++;
	if($line == 4){
	#开始统计质量		
	my @qual = split(//, $_); 
	my $len = @qual;
	for ($position = 1; $position <= $len; $position++ ) {
		$count{$position} += 1;
		my $Q = shift @qual;
		my $pred_Q = ord ($Q) - 33;
		if ($pred_Q >= 20) { 
			$count_Q{$position} += 1;
		}
	}
	$line = 0;
	}else{}
}
close IN;
print "position\tQ20\tTotal\tRatio\n";
@key =sort {$a <=> $b} keys %count;
for (@key) {
	my $ratio = $count_Q{$_}/$count{$_} * 100;
	print "$_\t$count_Q{$_}\t$count{$_}\t$ratio\n";
}
exit;
