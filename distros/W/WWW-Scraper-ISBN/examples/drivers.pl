#!/usr/bin/perl -w
use strict;

use WWW::Scraper::ISBN;

print "VERSION: $WWW::Scraper::ISBN::VERSION\n";

my $isbn = WWW::Scraper::ISBN->new();
my @drivers = $isbn->available_drivers();
print "Available: $_\n"    for(@drivers);
