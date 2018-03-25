#!/usr/bin/perl

use warnings;
use 5.012;

my $usage = <<_EOUSAGE_;

#################################################################################
#	
#	perl $0 in_RM_SAM pick_back_SAM abandoned_SAM coverage_threshhold indentity_threshhold
#	
###################################################################################

_EOUSAGE_
	;

# 传入参数	
my $in_sam=shift;
my $out_sam=shift;
my $aban_sam = shift;
my $cov_th = shift;
my $idtt_th = shift;

# 检查参数
die $usage unless ($in_sam && $out_sam && $aban_sam);

open INSAM,'<',$in_sam or die "can't open the input sam file $in_sam:$!";
open OUTSAM,'>',$out_sam or die "can't create the output sam file $out_sam:$!";
open ABANSAM, ">", $aban_sam or die "Can't output the abandoned sam record!\n";

############
## 主程序 ##
############

my $rawCount;
my $remainCount;

# 读入sam文件并计算coverage和identity
while(<INSAM>){
	$_ =~ s/[\r\n]+//;
	my $sClipLen = 0; 
	my $editDis;
	my $samRecord = $_;
	# 对行切片
	my @F = split /\t/, $_;
	# 跳过flag为2048和2064的supplementary alignments
	if (($F[1] == 2048 ) || ($F[1] == 2064)) {
		say ABANSAM;
		next;
	}
	# 统计representative alignment个数
	$rawCount ++;
	# sam中序列长度
	my $seqLen = length($F[9]); 
	# 捕获NM tag中的编辑距离，如果没有NM tag，则直接退出
	if (/NM:i:(\d+)\s+/){
		$editDis = $1;
	}else{
		die "$0 is not proper for this work. No NM tags in SAM record in line $.!\n";
	}
	# 计算cigar中所有soft clipping长度
	my @S = map {/(\d+)S/g} $F[5]; 
	for (@S) {
		$sClipLen += $_;
	}
	# 计算coverage = （序列长度 - 两端soft clipping长度） / 序列长度
	my $cov = ($seqLen - $sClipLen) / $seqLen;
	# 计算identity = 1 - 编辑距离 / （序列长度 - 两端soft clipping长度）
	my $idtt = 1 - $editDis / ($seqLen - $sClipLen);
	# 当且仅当coverage和identity以及两端softclipping个数同时满足阈值时，输出当前行
	if (($cov >= $cov_th) && ($idtt >= $idtt_th)){
		# 统计保留下来的记录个数
		$remainCount ++;
		say OUTSAM $samRecord;
	}else{
		say ABANSAM $samRecord;
	}
	# 测试用，手动check一下softclip的程度
	# if (($cov >= 0.6) && ($cov <= 0.7)){
		# say OUTSAM $samRecord;
	# }
}

close INSAM;
close OUTSAM;
close ABANSAM;

# 在标准输出打印filtering的统计信息
say "Total representative alignment count: $rawCount";
my $ratio = $remainCount / $rawCount;
say "Remaining alignment ratio: $ratio";

__END__