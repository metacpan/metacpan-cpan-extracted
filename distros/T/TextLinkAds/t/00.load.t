#!perl -wT

use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'TextLinkAds' );

my $tla = TextLinkAds->new();
isa_ok( $tla, 'TextLinkAds' );

diag( "Testing TextLinkAds $TextLinkAds::VERSION" );
