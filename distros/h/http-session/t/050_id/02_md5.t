use strict;
use warnings;
use Test::More;

plan tests => 2;
require HTTP::Session::ID::MD5;

is(length(HTTP::Session::ID::MD5->generate_id(10)), 10, 'check length');

cmp_ok(HTTP::Session::ID::MD5->generate_id(10), 'ne', HTTP::Session::ID::MD5->generate_id(10), 'unique');

