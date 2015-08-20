#!/usr/bin/env perl
use strict;
my $usage="
	perl $0 sample.list suffix
#ARGV:
	sample.list	A list file containing all fastq file name with suffix
	suffix 	
";
our $list=shift;
our $suffix=shift;
our $read_num=shift; #取前n个read来找接头，太少了会找到空字串，太多了会找到adapter前面随机相同的部分
die $usage unless (-s $list);
$read_num=10 unless ($read_num); #因为相邻2个read之间在接头前有1bp随机相同的可能性很高，经验值是10-15最好
our $shortest=8;  #太短的公共子串没意义，因此不考虑
our $adapter_prefix=11;  #需要读取adapter前几个bp进行搜索

#############
##  主程序 ##
#############
open LIST,'<',$list or die "Can't open the sample list\n$!";
while (<LIST>){ 
		chomp;
		my @ta = split(/\t/, $_);
		my $sample_file=$ta[0].".$suffix";
		my $adapter=$ta[2];
		my $adapter_len=length($adapter);
		my $adapter1;
		if($adapter_len>$adapter_prefix){
			$adapter1=substr($adapter,0,$adapter_prefix);
		}else{$adapter1=$adapter;}
		my $adapter_reads1 =  `grep  $adapter1 $sample_file | wc -l`;
		my $adapter2="^$adapter1";#空adapter的数量，这个必须有	
		my $adapter_reads2 =  `grep -P $adapter2 $sample_file | wc -l`;
		my $return =  `wc -l $sample_file`;
		my @total_lines=split(/ /,$return);
		my $total_reads=$total_lines[0]/4;
		chomp($adapter_reads1);
		chomp($adapter_reads2);
		my $ratio1=sprintf("%.2f", 1.0*$adapter_reads1/$total_reads);
		my $ratio2=sprintf("%.3f", 1.0*$adapter_reads2/$total_reads);
		#输出6列信息，文件名，read长度，adapter序列，adapter长度，adapter1比例，adapter2比例
		print "$ta[0]\t$ta[1]\t$adapter\t$adapter_len\t$ratio1($adapter_reads1\/$total_reads)\t$ratio2($adapter_reads2\/$total_reads)\n";

}
close LIST;
