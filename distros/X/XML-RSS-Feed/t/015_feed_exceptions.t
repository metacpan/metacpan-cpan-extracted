#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use Time::HiRes;

BEGIN { use_ok('XML::RSS::Feed') }

my $feed = XML::RSS::Feed->new(
    url            => "http://www.jbisbee.com/rdf/",
    name           => 'jbisbee',
    headline_as_id => 1,
);

$SIG{__WARN__} = build_warn("Failed to parse RSS XML");
$feed->parse("malformed XML string");
ok( $feed->num_headlines == 0, "force parse to fail" );

$feed->process( [] );
ok( $feed->num_headlines == 0, "call process without any items" );

$SIG{__WARN__} = build_warn(
    "Either item, url/headline. or url/description are required");
$feed->process( [ { bad => 1 } ] );

ok( $feed->num_headlines == 0, "call process with one bad item" );

sub build_warn {
    my @args = @_;
    return sub { my ($warn) = @_; like( $warn, qr/$_/i, $_ ) for @args };
}
