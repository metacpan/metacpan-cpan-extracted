#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use Time::HiRes;

BEGIN { use_ok('XML::RSS::Feed') }

my $feed = XML::RSS::Feed->new(
    url            => "http://www.jbisbee.com/rdf/",
    name           => 'jbisbee',
    headline_as_id => 1,
);
isa_ok( $feed, 'XML::RSS::Feed' );

my $time = Time::HiRes::time();
$feed->set_last_updated($time);
ok( $time == $feed->last_updated_hires, "testing last_updated_hires" );
ok( int($time) == $feed->last_updated, "testing last_updated" );
