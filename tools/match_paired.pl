#!/usr/bin/perl -w 
use strict; 
!@ARGV and die "
	perl $0 f1 f2 [a|n] \n	
	a :( add ) means all ids of records in both files DO NOT contain '/1' or '/2', processed by bwa,
	n :( not add ) means all ids of records in both files contain '/1' or '/2', ;
"; 

#������;����ȡfastq_clean�����˫�˲����ļ��е���Զ���
#��������ǳɶ�˫�˲����ļ������޺�׺������׺��������".clean"
#��������ļ�$f1������ǰ 

#################
## �����������##
#################
my $f1 = shift; 
my $f2 = shift; 
my $flag=shift;
( -f $f1.".clean" and -f $f2.".clean" and $flag =~/[an]/) or die "perl $0 $f1.clean $f2.clean\n"; 

#################
##  ������ʼ ##
#################

# ������������������Ϊ�ļ���������洫�ݲ�����
my ($in1, $in2); 
#���������ļ����
open $in1,"$f1.clean" or die; 
open $in2,"$f2.clean" or die; 
#��������ļ����,ǿ�ƹ涨�����ļ����������и�ʽ
$f1=~/^(\S+)_1/;
open O1,'>',"$f1.fq" or die; 
open O2,'>',"$f2.fq" or die; 
open OS,'>',"$1_S.fq" or die; 
print STDOUT "Dealing files: $f1 $f2\n"; 
my ($rec1r, $idx1, $rec2r, $idx2); 
#����3���������ֱ������Եģ�������ͷ������read����
my ($p, $s1, $s2) = (0,0,0); 
if ( !eof($in1) and !eof($in2) ) {
	($rec1r, $idx1) = &readRecord($in1,"f"); #�����1���ļ��������������
	($rec2r, $idx2) = &readRecord($in2,"r"); #�����2���ļ��������������
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

# �����Եģ�����Ե�ͳ�ƽ��
my $forward = $p/($p+$s1)*1.0; 
my $reverse = $p/($p+$s2)*1.0; ;  
print "$p paired reads in forward vs reverse: $forward\t$reverse\n"; 


##############
##  �ӳ���  ##
##############
# �������id�е����֣������ʽ��Fastq_clean�����
# �����ʽ������"-����"��β��������ȡ��$idx
sub readRecord {
	my $rec = readline($_[0]); 
	chomp($rec);
	my $idx=0; #ͨ��id��Ҫ���أ����������������
	if($flag eq 'a'){ #�����Ҫ���"/1""/2"
		$rec =~ m/-(\d+)$/ or die "Failed at line:$rec\n";
		$idx = $1;
		if($_[1] eq "f"){ 
			$rec=$rec."/1\n"; # ���"/1"
		}else{$rec=$rec."/2\n";}

	}else{
		$rec =~ m/-(\d+)\// or die "Failed at line:$rec\n";
		$idx = $1;
		#ǰ��ȥ���˻��з����˴�����
		$rec.="\n";
	}
	#�����ٶ���3�У��õ�����read���ڷ���
	$rec = $rec.readline($_[0]).readline($_[0]).readline($_[0]); 
	return(\$rec, $idx); 
}
