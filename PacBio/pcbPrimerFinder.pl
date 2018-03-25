#! /usr/bin/perl
# 开启strict、say和~~等新特性
use 5.012;


my $ccs_file = $ARGV[0];
# 无第二个参数时默认值设置为30
my $polyT_count = $ARGV[1] ? $ARGV[1] : 30;


open CCS, $ccs_file or die "No CCS file!\n";
open HEAD, ">", "5'primer_list.txt" or die "Cannot create output file!\n";
open TAIL, ">", "3'primer_list.txt" or die "Cannot create output file!\n";


# 修改换行符为fasta的id开头字符>，便于把整条记录当作整行读入，慎用
$/ = ">";
my %head;
my %tail;


while (<CCS>) {
	# 将每条fasta记录以换行符split
	my @F = split /[\r\n]/, $_;
	# 拿出我们不需要的id
	shift @F;
	# 去掉大于号（因为作为换行符因此并不会被shift掉）
	@F = map{s/>//gr} @F;
	# 利用join函数将list context转换为scalar context
	my $seq = join '',@F;
	# 此处map的运算优先级由右至左。右边第一个map返回一个array，作为左边的map中函数的参数传递进来继续运算
	my @tail_head = map {&rev_com($_)} map {/(.+)T{$polyT_count}.+(.{30})$/} $seq;
	$head{@tail_head[1]}++ if (@tail_head[1] ne '');
	$tail{@tail_head[0]}++ if (@tail_head[0] ne '');
}


# 以下代码块为另一种常见写法，可用于按list提取fasta序列等，此处不推荐，因为无法直接按行操作，效率较低
=pod
while (<CCS>) {
	if (/^>/) {
		next;
	}else{
		my $line .= $_;
	}
}
=cut


for (sort { $head{$b} <=> $head{$a} } keys %head) {
	say HEAD "$_\t$head{$_}";
}


for (sort { $tail{$b} <=> $tail{$a} } keys %tail) {
	say TAIL "$_\t$tail{$_}";
}


sub rev_com {
	my $seq = shift;
	$seq =~ s/[\r\n]+//;
	my @seq = split qq{},$seq;
	@seq = reverse @seq;
	$seq = join q{},@seq;
	$seq =~ tr/ATCGatcg/TAGCtagc/;
	return $seq;
}