#!/usr/bin/env perl
use strict;
use warnings;

#用于统计fastq文件指定列的ATCG含量及Q20碱基百分比

my $usage = <<_EOUSAGE_;

#########################################################################################
# $0 <file_list> <suffix_string> <col_num> > report
#                                  
# Required(3):
#  file_list	The name of a txt file containing a list of input file names without any suffix
#  suffix	The suffix of the file in the list
#  col_num	specify the col to be stated
###########################################################################################

_EOUSAGE_
;
#################
## 输入参数处理##
#################
my $list = shift;
my $suffix = shift;
my $col_num=shift;
die $usage unless (-s $list && $suffix && $col_num);

#################
##  主程序开始 ##
#################
open LIST,'<',$list or die "Can't open the sample list\n$!";
print "sample_name\tA\tT\tC\tG\tN\tQ20\n"; #先打印表头
while(<LIST>){
	my @cols = split(/\t/, $_);
	&stat_col($cols[0],$suffix,$col_num);
}
close(LIST);

#################
##    子程序   ##
#################
sub stat_col{
	my $sample=shift;
	my $suffix=shift;
	my $col_num=shift;
	my $file=$sample.".$suffix";
	open IN,"<$file" or die "File $file not found error here\n";
	my $count_Q20;
	my $line = 0; #行号记录
	my ($count_A,$count_T,$count_C,$count_G,$total_bases); 
	my $count_N=0;
	while(<IN>){
		chomp;
		$line++;
		#统计ATCG总量
		if($line == 2){
			my $seq=(split('',$_))[$col_num-1];
			if ($seq=~/[aA]/){
				$count_A++;
			}elsif($seq=~/[tT]/){
				$count_T++;
			}elsif($seq=~/[cC]/){
				$count_C++;
			}elsif($seq=~/[gG]/){
				$count_G++;
			}else{
				$count_N++;
			}
			$total_bases++;
		}
		#统计每列Q20总数
		if($line == 4){
			my @qual = (split(//,$_)); 
			my $pred_Q = ord ($qual[$col_num-1]) - 33;
			if ($pred_Q >= 20) { 
				$count_Q20++;
			}
			else{print $total_bases."\t".$_."\n";}
			$line = 0;
		}
	}
	close(IN);
	print $sample,sprintf("\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n",$count_A/$total_bases*100,$count_T/$total_bases*100,$count_C/$total_bases*100,$count_G/$total_bases*100,$count_A/$total_bases*100,$count_N/$total_bases*100,$count_Q20/$total_bases*100);
}


