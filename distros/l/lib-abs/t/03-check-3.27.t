#!/usr/bin/env perl -w

use strict;
BEGIN {
	( my $lib = $0 ) =~ s{[^/\\]+$}{lib/3.27/Cwd.pm};
	require $lib;
}
if ($^O eq 'MSWin32') {
	print "1..0 # SKIP does not work on Windows\n";
} else {
	( my $exe = $0 ) =~ s{[^/\\]+$}{check.pl};
	do $exe or die $@;
}

