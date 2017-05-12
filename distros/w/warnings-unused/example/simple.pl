#!perl -w
use 5.008_001;
use strict;
use warnings;
use warnings::unused;

my $a_unused; # unused

sub foo{
	our $global = sub{
		my $a_unused; # shadowing
		$a_unused++;
		$a_unused++;
	};

	my %b_unused;

	my @bar;
	if(0){
		my $c_unused = sub{ @bar }; # never reached, but checked
	}

	return \my $d_unused; # possibly used, but complained
}

{
	no warnings 'once';
	my $xyz; # unused but the warning is disabled
}

print "done.\n";
