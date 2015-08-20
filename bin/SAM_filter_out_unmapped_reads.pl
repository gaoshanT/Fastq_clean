#!/usr/bin/env perl

use strict;
use FindBin;
use lib ("$FindBin::Bin/PerlLib");#调用"/PerlLib"中的模块
use SAM_reader;
use SAM_entry;

my $usage = "usage: SAM_filter_out_unmapped_reads.pl <file.sam> out.unmapped out.mapped > result.sam\n";

my $sam_file = $ARGV[0] or die $usage;#输入文件，sam格式，这个参数是必须的
my $outputfile = $ARGV[1];#记录所有unmapped的reads，格式fastq，这个参数不是必须的
my $outputfile2 = $ARGV[2];#记录所有mapped的reads，格式fastq，这个参数不是必须的

open(OUT,">$outputfile");
open(OUT2,">$outputfile2");
main: {

	my $sam_reader = new SAM_reader($sam_file);   
        my $filtered_count = 0;
        my $total_count = 0;
           
	while ($sam_reader->has_next()) {
		
		my $sam_entry = $sam_reader->get_next();
		$total_count++;#记录输入文件的read总数，只有bwa的输出保证read数和sam文件行数相等       
        if ($sam_entry->is_query_unmapped()) {#如果该read无映射
				$filtered_count++;#记录unmapped文件的的read总数，对任何程序输出的sam文件都有效
				my @current_entry=$sam_entry->get_fields();
				print OUT "@".$current_entry[0]."\n".$current_entry[9]."\n"."+"."\n".$current_entry[10]."\n";	 
            }
            else {#如果该read有映射
		        if($outputfile2){#如果指定了输出文件，该read信息就输出
				my @current_entry=$sam_entry->get_fields();
				print OUT2 "@".$current_entry[0]."\n".$current_entry[9]."\n"."+"."\n".$current_entry[10]."\n";
			    }
			print $sam_entry->toString() . "\n";#同时输出该sam记录到标准输出
            }
        }
    #输出unmapped reads的和全部reads的数量（仅对bwa输出有效），因此比例也是仅对bwa输出有效
    print STDERR "this program filtered $filtered_count out of $total_count reads (" . sprintf("%.2f", $filtered_count / $total_count * 100) . ") as unmapped reads, only for BWA\n";
    exit(0);

}
close(OUT);
close(OUT2);