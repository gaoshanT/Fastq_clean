package WigParser;

use strict;
use warnings;


sub parse_wig {
	my ($wig_file) = @_;

	my %scaff_to_coverage;
    
	print STDERR "-retrieving max positions per scaffold\n";
	my %max_vals_for_scaffs = &_parse_max_scaff_lengths($wig_file);
	
	print STDERR "-preallocating memory for coverage\n";
	## preallocate arrays for coverage

	my $sum_pos = 0;
	foreach my $scaff (keys %max_vals_for_scaffs) {
		my $max_val = $max_vals_for_scaffs{$scaff};

		my @cov_vals = ();
		$#cov_vals = $max_val + 1;
		
		for my $index (0..$max_val) {
			$cov_vals[$index] = int(0);
		}
		$scaff_to_coverage{$scaff} = \@cov_vals;
		
		$sum_pos += $max_val;
	
	}

	print STDERR "- $sum_pos bases represented\n";

	print STDERR "-populating coverage data into memory.\n";
	
	my $scaff = undef;

	open (my $fh, $wig_file) or die "Error, cannot open file $wig_file";
	while (<$fh>) {
		if (/^track/) { next; };
		if (/chrom=(\S+)/) {
			$scaff = $1;
			next;
		}
		chomp;
		my ($pos, $val) = split(/\s+/);
		$scaff_to_coverage{$scaff}->[$pos] += int($val);
		
	}
	
	close $fh;

	return(%scaff_to_coverage);
}



### Private

sub _parse_max_scaff_lengths {
	my ($wig_file) = @_;

	my %scaff_to_max_vals;
	
	my $scaff = "";


	my $counter = 0;
	open (my $fh, $wig_file) or die "Error, cannot open file $wig_file";
	while (<$fh>) {
		if (/^track/) { next; };
		if (/chrom=(\S+)/) {
			$scaff = $1;
			next;
		}
		chomp;
		my ($pos, $val) = split(/\s+/);
		$scaff_to_max_vals{$scaff} = $pos;
		
		#print "scaff: $scaff\t$pos=> $val\n";
		
		$counter++;

		#if ($counter > 100000) { last; }
	}
	
	close $fh;

	return(%scaff_to_max_vals);
}

1; #EOM

