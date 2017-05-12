#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use WWW::NZPost::Tracking;

BEGIN {
    require Test::More;
    if( $ENV{NZPOST_DEV_KEY} ) {
        Test::More::plan( tests => 2 );
    } else {
        Test::More::plan(
            skip_all => 'these tests require a test api key',
        );
    }
};

my $nzp = WWW::NZPost::Tracking->new(
    license_key     => $ENV{NZPOST_DEV_KEY},
    user_ip_address => '10.10.10.4',
    mock            => 1,
);

my $package = $nzp->track('AS000000001NZ');
my @events  = $package->events;

is( $events[0]->date, "21/09/2009" );
is( $package->tracking_number, 'AS000000001NZ' );

