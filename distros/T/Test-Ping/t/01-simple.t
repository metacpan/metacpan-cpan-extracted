#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Test::Ping;

my $good_host = '127.0.0.1';
ping_ok( $good_host, "able to ping $good_host" );

