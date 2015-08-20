#!/usr/bin/perl -w 
use strict;

if (@ARGV < 1)
{
  print "usage: $0 input output\n";
  exit(0);
}

our $input = $ARGV[0]; #输入文件
our $output = $ARGV[1]; #输入文件

open(IN, "$input");
open(OUT, ">$output");
while (<IN>) {
	chomp; 
	my @ta = split(/\t/, $_);
	if($ta[1] eq "adapter was not found"){
		print OUT $ta[0]."\t".$ta[1]."\n";
	}else{
		my $adapter_len=11;
		if($ta[1]<=36){
			$adapter_len=8;
		} 
		print OUT $ta[0]."\t".$ta[2]."\t".$adapter_len."\n";
	}
}
close(IN);
close(OUT);