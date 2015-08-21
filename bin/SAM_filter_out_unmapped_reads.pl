#!/usr/bin/env perl

use strict;
use FindBin;
use lib ("$FindBin::Bin/PerlLib");#����"/PerlLib"�е�ģ��
use SAM_reader;
use SAM_entry;

my $usage = "usage: SAM_filter_out_unmapped_reads.pl <file.sam> out.unmapped out.mapped > result.sam\n";

my $sam_file = $ARGV[0] or die $usage;#�����ļ���sam��ʽ����������Ǳ����
my $outputfile = $ARGV[1];#��¼����unmapped��reads����ʽfastq������������Ǳ����
my $outputfile2 = $ARGV[2];#��¼����mapped��reads����ʽfastq������������Ǳ����

open(OUT,">$outputfile");
open(OUT2,">$outputfile2");
main: {

	my $sam_reader = new SAM_reader($sam_file);   
        my $filtered_count = 0;
        my $total_count = 0;
           
	while ($sam_reader->has_next()) {
		
		my $sam_entry = $sam_reader->get_next();
		$total_count++;#��¼�����ļ���read������ֻ��bwa�������֤read����sam�ļ��������       
        if ($sam_entry->is_query_unmapped()) {#�����read��ӳ��
				$filtered_count++;#��¼unmapped�ļ��ĵ�read���������κγ��������sam�ļ�����Ч
				my @current_entry=$sam_entry->get_fields();
				print OUT "@".$current_entry[0]."\n".$current_entry[9]."\n"."+"."\n".$current_entry[10]."\n";	 
            }
            else {#�����read��ӳ��
		        if($outputfile2){#���ָ��������ļ�����read��Ϣ�����
				my @current_entry=$sam_entry->get_fields();
				print OUT2 "@".$current_entry[0]."\n".$current_entry[9]."\n"."+"."\n".$current_entry[10]."\n";
			    }
			print $sam_entry->toString() . "\n";#ͬʱ�����sam��¼����׼���
            }
        }
    #���unmapped reads�ĺ�ȫ��reads������������bwa�����Ч������˱���Ҳ�ǽ���bwa�����Ч
    print STDERR "this program filtered $filtered_count out of $total_count reads (" . sprintf("%.2f", $filtered_count / $total_count * 100) . ") as unmapped reads, only for BWA\n";
    exit(0);

}
close(OUT);
close(OUT2);