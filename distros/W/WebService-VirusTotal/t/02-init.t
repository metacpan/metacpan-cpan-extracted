#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use WebService::VirusTotal;
    my $VT = WebService::VirusTotal->new();
    $VT->apikey("bogus key for testing the module only");
    ok( $VT->init() );
}

