#!/usr/bin/env perl
use strict;
use warnings;

print "\n\n";
print "QUERY_STRING: ", $ENV{QUERY_STRING} // '-', "\n";
