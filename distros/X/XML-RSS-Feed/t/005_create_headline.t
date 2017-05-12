#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 216;

BEGIN {
    use_ok('XML::RSS::Feed');
    use_ok('XML::RSS::Headline');
}

my $feed = XML::RSS::Feed->new(
    url  => "http://www.jbisbee.com/rdf/",
    name => 'jbisbee',
);
isa_ok( $feed, 'XML::RSS::Feed' );

my $headline = XML::RSS::Headline->new(
    url      => "http://www.jbisbee.com/testurl/1",
    headline => "Test Headline",
);
isa_ok( $headline, 'XML::RSS::Headline' );

my $headline_as_id = XML::RSS::Headline->new(
    url            => "http://www.jbisbee.com/testurl/1",
    headline       => "Test Headline\nLine 2",
    headline_as_id => 1,
);
ok( $headline_as_id->headline, "headline_as_id headline" );
ok( !$headline_as_id->item, "making sure method item returns false" );

my $hires_time = Time::HiRes::time();
my $new_time   = $hires_time;
ok( $headline_as_id->set_first_seen($hires_time), "set_first_seen" );
ok( $headline_as_id->first_seen_hires == $hires_time,
    "Checking first_seen_hires" );
ok( $headline_as_id->first_seen == int $hires_time, "Checking first_seen" );
ok( $headline_as_id->set_first_seen, "Checking first_seen bool" );

$headline_as_id->timestamp($hires_time);
my $timestamp = $headline_as_id->timestamp();
ok( $hires_time == $timestamp, "set/get headline timestamp" );

ok( $headline_as_id->id, "get id when headline_as_id is true" );

my $headline_ref = $headline_as_id->multiline_headline;
my @headlines    = $headline_as_id->multiline_headline;
ok( ref $headline_ref eq "ARRAY", "multiline headline as array ref" );
ok( @headlines == 2, "multiline headline as array" );

isa_ok( $headline, 'XML::RSS::Headline' );
my $iterations = 100;
my $title      = "This is a test 1";
my $url        = "http://www.jbisbee.com/test/url/1";

$feed->pre_process();
for my $i ( 1 .. $iterations ) {
    $feed->create_headline(
        headline => ++$title,
        url      => ++$url,
    );
    cmp_ok( $feed->num_headlines, '==', $i, "Verify num_headlines $i" );
    cmp_ok( $feed->late_breaking_news, '==', $i,
        "Verify late_breaking_news $i" );
}
$feed->post_process();
cmp_ok( $feed->late_breaking_news, '==', 100,
    "Verify mark_all_headlines_read" );
