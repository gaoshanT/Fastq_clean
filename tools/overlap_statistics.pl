#!/usr/bin/env perl
use strict;
use warnings;

#用于对于配对测通文库的overlap的统计

my $usage = <<_EOUSAGE_;

#########################################################################################
# perl $0 <IN_FQ_1> <IN_FQ_2> <OUT_FQ_1> <OUT_FQ_2> <ALN1> <ALN2>
#                                  
# Required:
#  <IN_FQ_1>	input forward_reads
#  <IN_FQ_2>	input reverse_reads
#  <OUT_FQ_1>	output forward_reads
#  <OUT_FQ_2>	output reverse_reads
#  <ALN1>		aln file
#  <ALN2>		aln file
###########################################################################################

_EOUSAGE_
	;
##############
## 全局变量 ##
##############
my $read_len; #对于得不到结果的读段，应考虑插入文库是否控制不佳，导致有较大片段，应调整此阈值到更高
my $overlap_th=10;  #低于这个长度，不再尝试overal，节省计算时间

#定义数组，用于击落错配位置信息
my @cum_pos_mM;

####################
## 命令行参数处理 ##
####################
my $in_1=shift;
my $in_2=shift;
my $out_1=shift; #输出正向测序数据，未来可以扩展为输出修正过的正向测序数据。
my $out_2=shift; #输出反向测序（反向互补）数据，以便人工检查overlap情况
my $aln1=shift;  #输出相似度90%以上的overlap
my $aln2=shift;  #输出相似度90%以下的overlap
die $usage unless (-s $in_1&&-s $in_2&&$out_1&&$out_2&&$aln1&&$aln2);


############
## 主程序 ##
############
open IN_FQ_1,'<',$in_1 or die "Can't open file $in_1\n:$!";
open IN_FQ_2,'<',$in_2 or die "Can't open file $in_2\n:$!";
open OUT_FQ_1,'>',$out_1 or die "Can't open file $out_1\n:$!";
open OUT_FQ_2,'>',$out_2 or die "Can't open file $out_2\n:$!";
open ALN1,'>',$aln1 or die "Can't open file $aln1\n:$!";
open ALN2,'>',$aln2 or die "Can't open file $aln2\n:$!";	



#正反读段文件必须位置配对
while(!eof(IN_FQ_1)){
    # 读入一个正向读段
	my $label_1=<IN_FQ_1>;
	my $seq_1=<IN_FQ_1>;
	$read_len= length($seq_1);
	my $add_label_1=<IN_FQ_1>;
	my $qual_1=<IN_FQ_1>;
	# 读入一个反向读段
	my $label_2=<IN_FQ_2>;
	my $seq_2=<IN_FQ_2>;
	my $add_label_2=<IN_FQ_2>;
	my $qual_2=<IN_FQ_2>;
	# 全部去除换行符，方便处理
	chomp ($label_1,$seq_1,$add_label_1,$qual_1,$label_2,$seq_2,$add_label_2,$qual_2);
	# 调用子函数得到overlap信息
	my $overlap=get_overlap($seq_1,$qual_1,$seq_2,$qual_2,$read_len,$overlap_th);
	#输出正向测序数据，这里没有必要
	#print OUT_FQ_1 "$label_1\n$overlap->[1]\n$add_label_1\n$overlap->[2]\n";
	my $seq_22=	rev_complement($seq_2);
	my $qual_22= rev($qual_2);
	#输出反向测序（反向互补）数据，以便人工检查overlap情况
	print OUT_FQ_2 "$label_2\n$seq_22\n$add_label_2\n$qual_22\n";
	
	my $aln_line; # 用”|“表示匹配的对齐信息
    # 输出所有配对读段的百分比距离
	#print $overlap->[0],"\n";
	
	#对于identity（1-汉明距离）大于等于0.9的输出到ALN1，可以用于统计illumina测序错误比例
	if(1-$overlap->[0]>=0.9){
		print ALN1 "$label_1\n";
		print ALN1 $overlap->[2],"\n";
		print ALN1 $overlap->[1],"\n";
		$aln_line=get_line($overlap);	
		print ALN1 $aln_line->[0],"\n";
		print ALN1 $overlap->[3],"\n";
		print ALN1 $overlap->[4],"\n";
		
	#否则输出到ALN2，用于查看无法匹配的原因
	}else{
		print ALN2 "$label_1\n";
		print ALN2 $overlap->[2],"\n";
		print ALN2 $overlap->[1],"\n";
		$aln_line=get_line($overlap);
		print ALN2 $aln_line->[0],"\n";
		print ALN2 $overlap->[3],"\n";
		print ALN2 $overlap->[4],"\n";
	}
	
	#统计overlap中每个位置中错配情况
	my @misMatch_table=@{$aln_line->[1]};
	for (0..$#misMatch_table) {
		$cum_pos_mM[$_]->[0]+=$misMatch_table[$_]->[0];
		$cum_pos_mM[$_]->[1]+=$misMatch_table[$_]->[1];
	}
}
#打印距离信息
# overlap中位置、该位置中所有的错配、正向质量高的（很可能反向错误）和反向质量高的（很可能正向错误）
# 由于overlap总是从正向5‘开始，与250bp正向测序位点一一对应
print "position\ttotal_mis\tForward_highQ\tReverse_highQ\n";
for (0..$#cum_pos_mM){
	print "$_\t",$cum_pos_mM[$_]->[0]+$cum_pos_mM[$_]->[1],"\t",$cum_pos_mM[$_]->[0],"\t",$cum_pos_mM[$_]->[1],"\n";
}

#关闭文件句柄
close IN_FQ_1;
close IN_FQ_2;
close OUT_FQ_1;
close OUT_FQ_2;
close ALN1;
close ALN2;

############
## 子程序 ##
############

#子程序,返回结果FLAG,重叠子串同时清理末端不匹配碱基
sub get_overlap {
    my $read1 = shift;	#必须是正向测序得到的read
	my $qual_1=shift;
    my $read2 = shift;	#必须是反向测序得到的read
	my $qual_2=shift;
    my $frag_len=shift;
    my $overlap_th = shift;	#必须满足最小overlap

	$read2 = rev_complement($read2);#取反向互补序列
	$qual_2=rev($qual_2);#反向读段质量值同时反转
	
	my @temp_reads=();
	my $sub_read1='';
	my $sub_qual1='';
	my $sub_read2='';
	my $sub_qual2='';
	for (my $i=$frag_len; $i >= $overlap_th; $i--){ #正向前$i个碱基与反向测序（反向互补）的后$i个碱基比较
		$sub_read1=substr($read1,0,$i); #截取正向读段
		$sub_qual1=substr($qual_1,0,$i);#截取正向质量数
		$sub_read2=substr($read2,length($read2)-$i,$i); #截取反向读段
		$sub_qual2=substr($qual_2,length($read2)-$i,$i);#截取反向质量数		
		my $distance = hamming($sub_read1,$sub_read2)*1.0/$i;#求2个字符串的汉明距离，再除以对比长度
		#保存汉明距离、反向测序读段、正向质量、反向测序读段（反向互补序列）和反向质量
		push @temp_reads,[$distance,$sub_read1,$sub_qual1,$sub_read2,$sub_qual2];	
	}
	@temp_reads=sort {$a->[0]<=>$b->[0]} @temp_reads;
	#返回最小距离对应的引用
	return $temp_reads[0]; 
}

sub rev_complement { 
	my $reads=shift;
	$reads=~s/\r?\n//;
	$reads=~tr/atcgATCG/tagcTAGC/;
	my @bases=split(q//,$reads);
	@bases=reverse @bases;
	my $seq=join '',@bases;
	return $seq;
}
sub rev{ 
	my $reads=shift;
	$reads=~s/\r?\n//;
	my @bases=split(q//,$reads);
	@bases=reverse @bases;
	my $seq=join '',@bases;
	return $seq;
}

sub get_line {
	my $aln_info_ref=shift;
	#获取每个比对结果的信息，舍弃距离信息
	my ($seq1,$qual1,$seq2,$qual2)=@{$aln_info_ref}[1,2,3,4];
	#设定输出数组
	my @misMatch_info;
	
	my @seq1_bases=split '',$seq1;
	my @qual1_bases=split '',$qual1;
	my @seq2_bases=split '',$seq2;
	my @qual2_bases=split '',$qual2;
	
	#记录对齐信息,'|'表示匹配，空格表示错配
	my $liner='';
	#该用索引，方便记录数值
	for my $index (0..$#seq1_bases){
		if ($seq1_bases[$index] eq $seq2_bases[$index]){
			$liner=$liner.q{|};
		}else{
			$liner=$liner.q{ };
			#若正反质量值相同,则暂时认定为正向错误
			if ($qual1_bases[$index] gt $qual2_bases[$index]){
				$misMatch_info[$index]->[0]++;
			}else{
				$misMatch_info[$index]->[1]++;
			}
		}
	}
	#对misMatch_info未定义数值进行补零
	for (0..$#misMatch_info){
		if (defined $misMatch_info[$_]->[0]){
		}else{
			$misMatch_info[$_]->[0]=0;
		}
		if (defined $misMatch_info[$_]->[1]){
		}else{
			$misMatch_info[$_]->[1]=0;
		}
	}
	#返回比对结果及距离信息数组
	return [$liner,\@misMatch_info];
}

sub hamming{length( $_[ 0 ] ) - ( ( $_[ 0 ] ^ $_[ 1 ] ) =~ tr[\0][\0] )}
