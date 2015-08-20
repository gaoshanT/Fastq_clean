#!/usr/bin/perl -w 
use strict; 
!@ARGV and die "
	perl $0 f1 f2 [a|n] \n	
	a :( add ) means all ids of records in both files DO NOT contain '/1' or '/2', processed by bwa,
	n :( not add ) means all ids of records in both files contain '/1' or '/2', ;
"; 

#程序用途：提取fastq_clean处理的双端测序文件中的配对读段
#输入参数是成对双端测序文件名（无后缀），后缀名必须是".clean"
#正向测序文件$f1必须在前 

#################
## 输入参数处理##
#################
my $f1 = shift; 
my $f2 = shift; 
my $flag=shift;
( -f $f1.".clean" and -f $f2.".clean" and $flag =~/[an]/) or die "perl $0 $f1.clean $f2.clean\n"; 

#################
##  主程序开始 ##
#################

# 定义下面两个变量作为文件句柄，后面传递参数用
my ($in1, $in2); 
#建立输入文件句柄
open $in1,"$f1.clean" or die; 
open $in2,"$f2.clean" or die; 
#建立输出文件句柄,强制规定输入文件必须是下列格式
$f1=~/^(\S+)_1/;
open O1,'>',"$f1.fq" or die; 
open O2,'>',"$f2.fq" or die; 
open OS,'>',"$1_S.fq" or die; 
print STDOUT "Dealing files: $f1 $f2\n"; 
my ($rec1r, $idx1, $rec2r, $idx2); 
#定义3个变量，分别计数配对的，正向不配和反向不配的read数量
my ($p, $s1, $s2) = (0,0,0); 
if ( !eof($in1) and !eof($in2) ) {
	($rec1r, $idx1) = &readRecord($in1,"f"); #处理第1个文件，正向测序数据
	($rec2r, $idx2) = &readRecord($in2,"r"); #处理第2个文件，反向测序数据
	MAPPING: 
	if ($idx1 == $idx2) {
		print O1 "$$rec1r"; $idx1 = -1; 
		print O2 "$$rec2r"; $idx2 = -1; 
		$p ++; 
		eof($in1) and goto TAIL; 
		eof($in2) and goto TAIL; 
		($rec1r, $idx1) = &readRecord($in1,"f"); 
		($rec2r, $idx2) = &readRecord($in2,"r"); 
		goto MAPPING; 
	}elsif ($idx1 < $idx2) {
		print OS "$$rec1r"; $idx1 = -1; $s1++; 
		eof($in1) and do goto TAIL; 
		($rec1r, $idx1) = &readRecord($in1,"f"); 
		goto MAPPING; 
	}else{
		print OS "$$rec2r"; $idx2 = -1; $s2++; 
		eof($in2) and do goto TAIL; 
		($rec2r, $idx2) = &readRecord($in2,"r");
		goto MAPPING; 
	}
}
TAIL: 
while (!eof($in1)) {
	if ($idx2 < 0 or $idx2 < $idx1) {
		$idx2 < 0 or do { print OS "$$rec2r"; $idx2=-1; $s2++; }; 
		$idx1 < 0 or do { print OS "$$rec1r"; $idx1=-1; $s1++; }; 
		while (!eof($in1)) {
			($rec1r, $idx1) = &readRecord($in1,"f"); 
			print OS "$$rec1r"; $s1++; $idx1 = -1; 
		}
	} elsif ($idx1 == $idx2) { 
		print O1 "$$rec1r"; $idx1 = -1; 
		print O2 "$$rec2r"; $idx2 = -1; 
		$p++; 
	} else {
		print OS "$$rec1r"; $idx1 = -1; $s1++; 
		($rec1r, $idx1) = &readRecord($in1,"f"); 
	}
}

while (!eof($in2)) {
	if ($idx1 < 0 or $idx1 < $idx2) {
		$idx1 < 0 or do { print OS "$$rec1r"; $idx1=-1; $s1++; }; 
		$idx2 < 0 or do { print OS "$$rec2r"; $idx2=-1; $s2++; }; 
		while (!eof($in2)) { 
			($rec2r, $idx2) = &readRecord($in2,"r"); 
			print OS "$$rec2r"; $s2++; $idx2 = -1; 
		} 
	} elsif ($idx1 == $idx2) {
		print O1 "$$rec1r"; $idx1 = -1; 
		print O2 "$$rec2r"; $idx2 = -1; 
		$p++; 
	} else {
		print OS "$$rec2r"; $idx2 = -1; $s2++; 
		($rec2r, $idx2) = &readRecord($in2,"r"); 
	}
}

$idx1 < 0 or do { print OS "$$rec1r"; $idx1=-1; $s1++; }; 
$idx2 < 0 or do { print OS "$$rec2r"; $idx2=-1; $s2++; }; 

close $in1; 
close $in2; 
close O1; 
close O2; 
close OS; 

# 输出配对的，不配对的统计结果
my $forward = $p/($p+$s1)*1.0; 
my $reverse = $p/($p+$s2)*1.0; ;  
print "$p paired reads in forward vs reverse: $forward\t$reverse\n"; 


##############
##  子程序  ##
##############
# 提出读段id中的数字，这个格式是Fastq_clean输出的
# 这个格式必须以"-数字"结尾，才能提取出$idx
sub readRecord {
	my $rec = readline($_[0]); 
	chomp($rec);
	my $idx=0; #通用id需要返回，用于主程序配对用
	if($flag eq 'a'){ #如果需要添加"/1""/2"
		$rec =~ m/-(\d+)$/ or die "Failed at line:$rec\n";
		$idx = $1;
		if($_[1] eq "f"){ 
			$rec=$rec."/1\n"; # 添加"/1"
		}else{$rec=$rec."/2\n";}

	}else{
		$rec =~ m/-(\d+)\// or die "Failed at line:$rec\n";
		$idx = $1;
		#前面去除了换行符，此处补上
		$rec.="\n";
	}
	#连续再读入3行，得到整个read用于返回
	$rec = $rec.readline($_[0]).readline($_[0]).readline($_[0]); 
	return(\$rec, $idx); 
}
