#!/usr/bin/perl -w 
use strict; 

# 程序用途：检查fastq_clean运行结果是否有错误报道
# 仅用于fastq_clean流程

if (@ARGV < 1)
{
  print "usage: $0 inputfile\n";
  exit(0);
}

our $input = $ARGV[0]; 
our @errors=("Error","Aborted","cannot","No","core dumped"); 

for my $err (@errors) {
	print "# This is information of ".$err."\n";
	my $return = `grep -n \'\\b$err\\b\' $input`;
	print $return."\n";
}



