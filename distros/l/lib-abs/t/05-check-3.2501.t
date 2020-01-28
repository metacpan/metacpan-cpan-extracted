#!/usr/bin/env perl -w

use strict;
BEGIN {
	( my $lib = $0 ) =~ s{[^/\\]+$}{lib/3.2501/Cwd.pm};
	require $lib;
}
if ($^O eq 'MSWin32') {
	print "1..0 # SKIP does not work on Windows\n";
} else {
	print "Test using Cwd $INC{'Cwd.pm'} $Cwd::VERSION, Perl $], $^X\n";
	( my $exe = $0 ) =~ s{[^/\\]+$}{check.pl};
	do $exe or die $@;
}
