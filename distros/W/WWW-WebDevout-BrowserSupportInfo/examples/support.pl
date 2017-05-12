#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: perl support.pl <what_to_lookup>\n"
    unless @ARGV;

my $What = shift;

use lib qw(../lib lib);
use WWW::WebDevout::BrowserSupportInfo;

my $wd = WWW::WebDevout::BrowserSupportInfo->new( long => 1 );

$wd->fetch( $What )
    or die "Error: " . $wd->error . "\n";

print "Support for " . $wd->what;

my $results = $wd->browser_results;

printf "\n\t%-20s: %s", $_, $results->{ $_ } || 'N/A'
    for sort keys %$results;

printf "\nYou can find more information on %s\n", $wd->uri_info;



