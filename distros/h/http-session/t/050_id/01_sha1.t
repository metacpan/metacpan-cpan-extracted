use strict;
use warnings;
use Test::More tests => 3;
require HTTP::Session::ID::SHA1;

like(HTTP::Session::ID::SHA1->generate_id(40), qr/^[0-9a-f]{40}$/, 'sha1 hex format');
is(length(HTTP::Session::ID::SHA1->generate_id(10)), 10, 'honors sid_length');
cmp_ok(HTTP::Session::ID::SHA1->generate_id(10), 'ne',
       HTTP::Session::ID::SHA1->generate_id(10), 'unique');
