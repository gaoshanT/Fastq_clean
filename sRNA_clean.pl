#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
#
# $0 ./conf/input.config
#
#  <input.config>  the configuration file containing all the parameters setting
#
#########################################################################################

_EOUSAGE_
	;

#################
##   全局变量  ##
#################
our $file_list;
our $suffix="fastq"; #输入文件（fastq格式）的后缀名
our $distance=2;     #adapter与read匹配时可允许的最大编辑距离，目前最多是1
our $levenshtein;#如果设定，此值自动转为1，表示使用levenshtein算法求编辑距离
our $max_N=0;     #剩下的reads中，剩下的N不能大于这个数
our $min_Len=15; #最后留下的reads必须大于等于15bp长度
our $CPU = 8; #程序调用的线程数量
our $shuffle_flag;

our $rRNA_removal;
our $virus_removal;
our $rRNA_reference="rRNA_silva111.fasta";
our $virus_reference= "vrl_genbank.fasta";#包括全部参考序列的文件名称（FASTA格式）
 
our $max_dist = 1;  #bwa允许的最大编辑距离 
our $max_open = 1;  #bwa允许的最大gap数量
our $max_extension = 1; #bwa允许的最大gap长度,-1表示不允许长gap
our $len_seed=15; #bwa中的种子区长度,100bp测序用50，50bp测序用36
our $dist_seed = 1; #bwa种子区允许的最大编辑距离
################################
##   设置所有目录和文件的路径 ##
################################
our $WORKING_DIR=cwd();#工作目录就是当前目录
our $DATABASE_DIR=$WORKING_DIR."/databases";#所有数据库文件所在的目录
our $BIN_DIR=$WORKING_DIR."/bin";#所有可执行文件所在的目录
our $Tools=$WORKING_DIR."/tools";#所有作为工具的可执行文件所在的目录

##################
## 程序参数处理 ##
##################
#  必须至少提供一个参数，才可以继续
die $usage unless (-s $ARGV[0]);
open CONF,'<',$ARGV[0] or die "Can't read configure file ".$ARGV[0]." :$!";
while(<CONF>){
    # 注释行与空行不处理
	next if (/^#/||/^\s*$/);
	# chomp可以同时去掉回车换行
	chomp;
	my ($option,$value)=split ('=',$_);
	die "$option has no value\n" if (($value eq '')||(!defined $value));
	if($option eq 'file_list'){$file_list=$value; print $value,"\n";}
		elsif($option eq 'suffix'){$suffix=$value}
		elsif($option eq 'distance'){$distance=$value}
		elsif($option eq 'levenshtein'){$levenshtein=$value}
		elsif($option eq 'max_N'){$max_N=$value}
		elsif($option eq 'min_Len'){$min_Len=$value}
		elsif($option eq 'CPU'){$CPU=$value}
		elsif($option eq 'shuffle_flag'){$shuffle_flag=$value}
		elsif($option eq 'rRNA_removal'){$rRNA_removal=$value}
		elsif($option eq 'rRNA_reference'){$rRNA_reference=$value}
		elsif($option eq 'virus_removal'){$virus_removal=$value}
		elsif($option eq 'virus_reference'){$virus_reference=$value}
		elsif($option eq 'max_dist'){$max_dist=$value}
		elsif($option eq 'max_open'){$max_open=$value}
		elsif($option eq 'max_extension'){$max_extension=$value}
		elsif($option eq 'len_seed'){$len_seed=$value}
		elsif($option eq 'dist_seed'){$dist_seed=$value}
		else {die "Unknow Option: $_\n"}
}

unless (-s $file_list) {#这个最重要参数必须有
	die $usage;
}


#################
##  主程序开始 ##
#################
main: {
    # 首先检查工作目录中是否含有所有输入数据文件，并且统一文件后缀名称为'.fastq'
    filelist_check($file_list);
	#输入文件（原始数据）必须".fastq"后缀，输出文件分别为".trimmed".$distance后缀，".unmatched".$distance后缀和".null".$distance后缀
    #这部分是clipper过程，如果不需要可以注释掉
	system("$Tools/fastq_clipper.pl --file_list $file_list --suffix $suffix --distance $distance --max_N $max_N --min_Len $min_Len --CPU $CPU");
	$suffix="trimmed".$distance;
	system("$BIN_DIR/files_name_change.pl --file_list $file_list --suffix1 $suffix --suffix2 clean");
	system("rm *.null*");
	system("rm *.unmatched*");
	system("cut -f1 $file_list > samples.list");
     
	#如果需要，就去除rRNA污染，输入文件必须是".clean"作为后缀
	if($rRNA_removal){	
		system("$BIN_DIR/bwa_remove.pl --file_list samples.list --reference $DATABASE_DIR/$rRNA_reference --max_dist $max_dist --max_open $max_open --max_extension $max_extension --len_seed $len_seed --dist_seed $dist_seed --thread_num $CPU");
		system("$BIN_DIR/files_name_change.pl --file_list samples.list --suffix1 unmapped --suffix2 clean");
	}
	#如果需要，就去除virus污染，输入文件必须是".clean"作为后缀
	if($virus_removal){	
		system("$BIN_DIR/bwa_remove.pl --file_list samples.list --reference $DATABASE_DIR/$virus_reference --max_dist $max_dist --max_open $max_open --max_extension $max_extension --len_seed $len_seed --dist_seed $dist_seed --thread_num $CPU");
		system("$BIN_DIR/files_name_change.pl --file_list samples.list --suffix1 unmapped --suffix2 clean");
	}
}

##############
##  子程序  ##
##############
sub filelist_check {
    my $list = shift;
	open(LIST, "$list");
	while(<LIST>){
		chomp;
		my @cols = split(/\t/, $_);
		my $file_name1=$cols[0].'.fastq'; #如果找到文件列表里面的文件（后缀名是'.fastq'）
		print $cols[0]."\n";
		unless(-s $file_name1){           #如果没有找到文件列表里面的文件（后缀名是'.fastq'）
			my $file_name2=$cols[0].'.raw'; #再找文件列表里面的文件（后缀名是'.raw'）
			unless (-s $file_name2){
				die "you must put the file $file_name1 in the $WORKING_DIR\n";#提示输入文件类型必须为'.fastq'后缀
			}
			rename $file_name2,$file_name1;#要保证下一步输入文件后缀名必须是'.fastq'
		}
	}
	close(LIST);
}
