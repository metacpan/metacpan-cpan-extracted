use strict;
use warnings;
use Test::More tests => 3;
require HTTP::Session::ID::MD5;

like(HTTP::Session::ID::MD5->generate_id(32), qr/^[0-9a-f]{32}$/, 'md5 hex format');
is(length(HTTP::Session::ID::MD5->generate_id(10)), 10, 'honors sid_length');
cmp_ok(HTTP::Session::ID::MD5->generate_id(10), 'ne',
       HTTP::Session::ID::MD5->generate_id(10), 'unique');
