#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('XML::RSS::Feed') }

my $feed = XML::RSS::Feed->new(
    url  => "http://www.jbisbee.com/rdf/",
    name => 'jbisbee',
);
isa_ok( $feed, 'XML::RSS::Feed' );

{
    local $SIG{'__WARN__'} = sub {};
    cmp_ok( $feed->failed_to_fetch, 'eq', "", "Verify that failed_to_fetch returns ''" );
    cmp_ok( $feed->failed_to_parse, 'eq', "", "Verify that failed_to_parse returns ''" );
}

