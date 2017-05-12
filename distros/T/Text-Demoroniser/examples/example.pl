#!/usr/bin/perl -w
use strict;

use Text::Demoroniser   qw(demoroniser demoroniser_utf8);

my $ex = $ARGV[0];

print "string: %s\n", $ex;
print "fixed:  %s\n", demoroniser($ex);
print "utf8:   %s\n", demoroniser_utf8($ex);
