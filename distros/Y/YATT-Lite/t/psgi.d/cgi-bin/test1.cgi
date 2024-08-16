#!/usr/bin/env perl
use strict;
use warnings;

print "\n\n";
print "Under doc_root, QUERY_STRING: ", $ENV{QUERY_STRING} // '-', "\n";
