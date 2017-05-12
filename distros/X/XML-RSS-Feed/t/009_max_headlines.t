#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 105;

BEGIN { use_ok('XML::RSS::Feed') }

my $max_headlines = 5;
my $iterations    = 100;
my $title         = "This is a test 1";
my $url           = "http://www.jbisbee.com/test/url/1";
cmp_ok( $max_headlines, "<", $iterations,
    "Max headlines must be less than iterations" );

my $feed = XML::RSS::Feed->new(
    url           => "http://www.jbisbee.com/rdf/",
    name          => 'jbisbee',
    max_headlines => $max_headlines,
);
isa_ok( $feed, 'XML::RSS::Feed' );

$feed->pre_process();

my @headlines = ();
for my $i ( 1 .. $iterations ) {
    my %hash = (
        headline => ++$title,
        url      => ++$url,
    );
    unshift @headlines, $hash{headline};
    $feed->create_headline(%hash);
    cmp_ok( $feed->num_headlines, '<=', $max_headlines,
        "Verify max_headlines $i" );
}
$feed->post_process();
cmp_ok( $feed->num_headlines, '==', $max_headlines, "Verify max_headlines" );

@headlines = splice( @headlines, 0, $max_headlines );

my @headlines2 = map { $_->headline } $feed->headlines;

ok( eq_array( \@headlines, \@headlines2 ),
    "Comparing before and after headlines"
);
