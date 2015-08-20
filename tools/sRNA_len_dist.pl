#!/usr/bin/perl
use strict;
use warnings;
use IO::File;
use Getopt::Long;
use Cwd;
my $usage = <<_EOUSAGE_;

#########################################################################################
# sRNA_len_dist.pl --sample [String] --image_type [String] --suffix [String]
#                                  
# Required(1):
#  --sample The name of the fastq or fasta file without the suffix file name
# Options(2):
#  --image_type The output image type of the small RNA length distribution plot [jpg]
#  --suffix the suffix file name of the sample [clean]
###########################################################################################

_EOUSAGE_
	;

our $sample;
our $image_type = "jpg";
our $suffix = "clean";
#################
## 输入参数处理##
#################
&GetOptions( 'sample=s' => \$sample,
		 'image_type=s' => \$image_type,
		 'suffix=s' => \$suffix
			 );

unless ($sample) {#至少需要1个参数
	die $usage;
}

our $input_file = $sample.".".$suffix;
our $output_table = $sample.".table";
our $output_plots = $sample.".pdf";
our $output_image = $sample.".".$image_type;

#############################################################
# Parse the sequence file and get length distribution 		#
#############################################################
my (    $seq_id,        # sequence id
        $format,        # format
        $sequence,      # sequence
        $seq_length,    # sequence length
);

my %length_dist;

my $fh = IO::File->new($input_file) || die "Can not open the file $input_file $!\n";
while(<$fh>)
{
	chomp;
	$seq_id = $_;
	if      ($seq_id =~ m/^>/) { $format = 'fasta'; $seq_id =~ s/^>//; }
	elsif   ($seq_id =~ m/^@/) { $format = 'fastq'; $seq_id =~ s/^@//; }
	else    { die "File format error at $seq_id\n"; }

	$sequence = <$fh>; chomp($sequence);
	$seq_length = length($sequence);
	if ( defined $length_dist{$seq_length} ) { $length_dist{$seq_length}++; }
	else { $length_dist{$seq_length} = 1; }
	if ($format eq 'fastq') { <$fh>; <$fh>; }
}
$fh->close;

my $out = IO::File->new(">".$output_table) || die "Can not open output table file $output_table $!\n";
#必须保证按照key（长度大小）排序，否则画图会带来问题
foreach my $len (sort{$a<=>$b} keys %length_dist)  {
	print $out "$len\t$length_dist{$len}\n";
}
$out->close;

#################################################
# draw length distribution using R				#
#################################################

my $R_LD =<< "END";
a<-read.table("$output_table");
x<-a[,2];
names(x) <- a[,1];
pdf("$output_plots",width=12,height=6);
barplot(x/sum(x), col="blue", xlab="Length(nt)", ylab="Frequency", main="$sample");
invisible(dev.off())
END

open R,"|/usr/bin/R --vanilla --slave" or die $!;#打开一个管道
print R $R_LD;
close R;


