#!/usr/bin/perl
use strict;

# ������;��ͳ��һ��fastq�ļ���
# ������fastq_clean����Q20�����Q >= 20���ı���

my $file = $ARGV[0] or die "Usage: $0 input > output\n";;

#################
##  ������ʼ ##
#################
open IN,"<$file" or die "File $file not found error here\n";
my $position;
my %count;	#ͳ��ÿ�м������
my %count_Q;	#ͳ��ÿ��Q20����
my @key;
my $line = 0;
while(<IN>){
	chomp;              #ÿ����һ�У�����ȥ���س�
	$line++;
	if($line == 4){
	#��ʼͳ������		
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
