#!/usr/bin/env perl -w

use strict;
BEGIN {
	( my $lib = $0 ) =~ s{[^/\\]+$}{lib/3.2501/Cwd.pm};
	require $lib;
}
print "Test using Cwd $INC{'Cwd.pm'} $Cwd::VERSION, Perl $], $^X\n";
( my $exe = $0 ) =~ s{[^/\\]+$}{check.pl};
do $exe or die $@;

