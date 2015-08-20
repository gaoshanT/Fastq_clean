#!/usr/bin/env perl
use strict;
use warnings;
my $usage="
Usage:
	perl $0 samples.list clean.log > clean.report
";

my $list=shift;
my $clean=shift;

die "The $list or $clean does not exists or is null\n\n$!" unless (-s $clean && -s $list);

open LIST,'<',$list or die "Can't open $list : $!";
my @list;
my %store_hash;

while(<LIST>){
	chomp;
	push @list,$_;
}
close LIST;

open CLEAN,'<',$clean or die "Can't open sample.list $clean : $!";
while(<CLEAN>){
	my $data= $_;
	my @data=split /\s+/;
	if ($.==1){
		print $data;
		next;
	}	
	next unless (@data==9);
	if (grep {$_ eq $data[0]} @list){
		push @{$store_hash{$data[0]}},$data;
		next;
	}
}
close CLEAN;
for (@list){
	print @{$store_hash{$_}};
}