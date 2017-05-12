#!/usr/bin/env perl
# head(1) utility for testing

# ------ pragmas
use warnings;
use strict;

# ------ define variables
my $count = 0;		# line count
my $line  = undef;	# current input line

while ($line = <>) {
	if (++$count < 100) {
		print $line;

		next;
	}

	exit(0);
}
