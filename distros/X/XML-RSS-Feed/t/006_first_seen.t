#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('XML::RSS::Feed') }

my $feed = XML::RSS::Feed->new(
    url  => "http://www.jbisbee.com/rdf/",
    name => 'jbisbee'
);
isa_ok( $feed, 'XML::RSS::Feed' );

my $title = "This is a test 1";
my $url   = "http://www.jbisbee.com/test/url/1";

$feed->pre_process();
$feed->create_headline( headline => ++$title, url => ++$url ) for 1 .. 100;
$feed->post_process();

my @headlines = $feed->headlines;
my @sorted_headlines
    = sort { $b->first_seen_hires <=> $a->first_seen_hires } $feed->headlines;
ok( eq_array( \@headlines, \@sorted_headlines ),
    "Validate first_seen_hires" );
