#!/usr/bin/env perl
use strict;
my $usage="
	perl $0 sample.list suffix read_number 
#ARGV:
	sample.list	A list file containing all fastq file name with suffix
	suffix 
	read_number
	
";
our $list=shift;
our $suffix=shift;
our $read_num=shift; #取前n个read来找接头，太少了会找到空字串，太多了会找到adapter前面随机相同的部分
die $usage unless (-s $list);
$read_num=10 unless ($read_num); #因为相邻2个read之间在接头前有1bp随机相同的可能性很高，经验值是10-15最好
our $shortest=8;  #太短的公共子串没意义，因此不考虑
our $read_len;  #需要读取read长度并输出

#############
##  主程序 ##
#############
open LIST,'<',$list or die "Can't open the sample list\n$!";
my $i=1;
while (<LIST>){ 
		chomp;
		my $sample_file=$_.".$suffix";
		my $adapter=&find_adapter($sample_file,$read_num*$i);
		if($adapter){
		    $i=0;
			my $adapter_len=length($adapter);
			# $adapter1是前面找到的接头的前11bp，用于在整个数据文件中grep
			my $adapter1;
			if(length($adapter)>11){
				$adapter1=substr($adapter,0,11);
			}else{$adapter1=$adapter;}
			my $adapter_reads1 =  `grep  $adapter1 $sample_file | wc -l`;
			# $adapter2表示含有$adapter1开头的序列，用于在整个数据文件中grep
			my $adapter2="^$adapter1";	
			my $adapter_reads2 =  `grep -P $adapter2 $sample_file | wc -l`;
			my $return =  `wc -l $sample_file`;
			my @total_lines=split(/ /,$return);
			my $total_reads=$total_lines[0]/4;
			chomp($adapter_reads1);
			chomp($adapter_reads2);
			my $ratio1=sprintf("%.2f", 1.0*$adapter_reads1/$total_reads);
			my $ratio2=sprintf("%.3f", 1.0*$adapter_reads2/$total_reads);
			#输出6列信息，文件名，read长度，adapter序列，adapter长度，adapter1比例，adapter2比例
			print "$_\t$read_len\t$adapter\t$adapter_len\t$ratio1($adapter_reads1\/$total_reads)\t$ratio2($adapter_reads2\/$total_reads)\n";
		}else{
		    if($i<=100){		
				$i=$i+1;			
				redo;
			}else{
				print "$_\tAdapter not found\n";
			}		
		}
}
close LIST;

#################
##  子程序     ##
#################
sub find_adapter {
	my $file_name=shift;
	my $read_num=shift;
	die "Can't find file $file_name\n$!" unless (-s $file_name);
	open SAMPLE,'<',$file_name or die "Can't read file $file_name\n";
	my @sample;
	for (1..$read_num){
		<SAMPLE>;
		my $str=<SAMPLE>;
		<SAMPLE>;<SAMPLE>;
		my $suffix=substr($str,length($str)-$shortest);
		#print $suffix."\n";
		if($suffix!~/[Nn]/){
			push @sample,$str;
		}else{redo;}
	}
	close SAMPLE;	
	
	chomp @sample;
	my @common_str;
	my $pre=shift @sample;
	while (@sample){
		my $cur=shift @sample;
		my $commmon_string=&max_common_substr($pre,$cur);
		if($commmon_string){
			push @common_str,$commmon_string;
		}
		$pre=$cur;
	}
	@common_str = sort {length($b)<=>length($a)} @common_str;
	return shift @common_str;
}


sub max_common_substr {
	my $str1=shift;
	my $str2=shift;
	my %hash1;
	my %hash2;
	my @strings;
	#$str1 =~ /(.*?)(?{$hash1{$1}=$1})(*F)/;	#旧算法，可能不太对
	#$str2 =~ /(.*?)(?{$hash2{$1}=$1})(*F)/;	#旧算法，可能不太对  
	#保存所有的字串到hash结构
	$read_len=length($str1);
	for (my $i=0;$i<=$read_len-$shortest;$i++){
		$hash1{substr($str1,$i,$read_len-$i)}=1;
		#print substr($str1,$i,$read_len-$i)."\n";
		$hash2{substr($str2,$i,$read_len-$i)}=1;
		#print substr($str2,$i,$read_len-$i)."\n";
	}	
	
	#将所有的公共字串存入数组
	for (keys %hash1){   
		push  @strings,$_ if exists $hash2{$_};      
	} 
	
	# 遍历数组内所有的公共子串，返回最长的
    my $max_len=0;
    my $max_string;		
	for (@strings){
		if(length($_)>$max_len){
			next if /[Nn]/;		
			$max_len=length($_);
			$max_string=$_;
		}  
	} 
	#print $max_string."!\n"; 	
	return $max_string;
}
