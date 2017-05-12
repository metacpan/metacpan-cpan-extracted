#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

BEGIN { use_ok('WebService::IMDBAPI'); }

my $imdbapi;    # WebService::IMDBAPI object

$imdbapi = WebService::IMDBAPI->new();
isa_ok( $imdbapi, 'WebService::IMDBAPI' );

# _generate_url()
my $got_url;
my $expected_url;

$expected_url = "http://imdbapi.org/?type=json&lang=en-US";
$got_url      = $imdbapi->_generate_url();
is( $got_url, $expected_url );

$expected_url = "http://imdbapi.org/?type=json&lang=en-US&foo=bar";
$got_url = $imdbapi->_generate_url( { foo => "bar" } );
is( $got_url, $expected_url );

# exceptions
throws_ok { $imdbapi->search_by_title() } qr/title is required/;
throws_ok { $imdbapi->search_by_id() } qr/id is required/;
