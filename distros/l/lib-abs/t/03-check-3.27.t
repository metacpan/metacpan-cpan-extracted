#!/usr/bin/env perl -w

use strict;
BEGIN {
	( my $lib = $0 ) =~ s{[^/\\]+$}{lib/3.27/Cwd.pm};
	require $lib;
}
( my $exe = $0 ) =~ s{[^/\\]+$}{check.pl};
do $exe or die $@;

