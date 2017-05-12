#!/usr/bin/perl

# Compile testing for WWW::ActiveState::PPM

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use LWP::Online ':skip_all';
use Test::More tests => 4;
use WWW::ActiveState::PPM;

# Create the scraper
my $scrape = WWW::ActiveState::PPM->new;
isa_ok( $scrape, 'WWW::ActiveState::PPM' );
is( $scrape->trace, '', '->trace is false by default' );
is( $scrape->version, '5.10', '->version is 5.10 by default' );

# Run the scraping
diag( "Doing a full test run, this could take a few minutes...\n" );
$scrape->run;

my $count = scalar(keys %{$scrape->{dists}});
diag( "Found $count packages" );
ok( $count > 1000, 'Found at least 1000 packages' );
