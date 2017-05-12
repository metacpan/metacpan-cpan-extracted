#!/usr/bin/env perl

use strict;
use warnings;
use constant TESTS => 12;
use Test::More tests => TESTS;

BEGIN { use_ok( 'WWW::Wordnik::API' ); }
require_ok( 'WWW::Wordnik::API' );

my $wn = WWW::Wordnik::API->new();

# defaults
is($wn->server_uri, 'http://api.wordnik.com/v4', 'get server_uri');
is($wn->api_key,    'YOUR KEY HERE',                 'get api_key'   );
is($wn->version,    4,                               'get version'   );
is($wn->format,     'json',                          'get format'    );
is($wn->cache,      10,                              'get cache'     );

is($wn->server_uri('http://www.example.com'), 'http://www.example.com', 'set server_uri');
is($wn->api_key('MY KEY HERE'),               'MY KEY HERE',            'set api_key'   );
eval {$wn->version(1_000_000)};
like($@,                              qr/Unsupported api version: '1000000'/,  'set version'   );
is($wn->format('xml'),               'xml',                           'set format'    );
is($wn->cache(2),                      2,                               'set cache'     );

done_testing(TESTS);
