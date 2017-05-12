#!perl

use strict;
use warnings;

use URI;
use Test::More tests => 17;

{
  ok my $guri = URI->new( 'geo:54.786989,-2.344214' ), 'created';
  isa_ok $guri, 'URI::geo';
  is $guri->scheme,    'geo',                     'scheme';
  is $guri->latitude,  54.786989,                 'latitude';
  is $guri->longitude, -2.344214,                 'longitude';
  is $guri->altitude,  undef,                     'altitude';
  is $guri->as_string, 'geo:54.786989,-2.344214', 'stringify';
  $guri->altitude( 120 );
  is $guri->altitude, 120, 'altitude set';
  is $guri->as_string, 'geo:54.786989,-2.344214,120',
   'stringify w/ alt';
  $guri->latitude( 55.167469 );
  $guri->longitude( -1.700663 );
  is $guri->as_string, 'geo:55.167469,-1.700663,120',
   'stringify updated w/ alt';
}

{
  ok my $guri = URI->new( 'geo:55.167469,-1.700663,120' ), 'created';
  my @loc = $guri->location;
  is_deeply [@loc], [ 55.167469, -1.700663, 120 ], 'got location';
}

{
  ok my $guri = URI->new( 'geo:-33,30' ), 'created';
  my @loc = $guri->location;
  is_deeply [@loc], [ -33, 30, undef ], 'got location';
}

{
  eval { URI->new( 'geo:1' ) };
  like $@, qr/Badly formed/, 'error ok';
}

{
  ok( URI->new( 'geo:55,1' )->eq( URI->new( 'geo:55,1' ) ), 'eq 1' );
  ok( URI->new( 'geo:90,1' )->eq( URI->new( 'geo:90,2' ) ), 'eq 2' );
}

# vim:ts=2:sw=2:et:ft=perl

