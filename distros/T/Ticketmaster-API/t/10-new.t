#!perl

use 5.006;

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
    use_ok( 'Ticketmaster::API' ) || print "Bail out!\n";
}

my $api_key         = '123Testing';
my $default_uri     = 'https://app.ticketmaster.com';
my $default_version = 'v1';
my $base_uri        = 'http://nothing.com';

my $tm_api = Ticketmaster::API->new(api_key => $api_key);
is($tm_api->api_key, $api_key, 'Confirm api_key');
is($tm_api->base_uri, $default_uri, 'Default URI found');
is($tm_api->version, $default_version, 'Default Version found');

$tm_api = Ticketmaster::API->new( api_key => $api_key, base_uri => 'http://nothing.com', version => 'v2');
is($tm_api->base_uri, $base_uri, 'Correct URI found');
is($tm_api->version, 'v2', 'Correct Version found');

$tm_api->api_key('something_new');
is($tm_api->api_key(), 'something_new', 'New API Key found');

# Exceptions
eval { my $api = Ticketmaster::API->new(); };
like($@, qr/^No api_key provided/, 'No API Key provided');
