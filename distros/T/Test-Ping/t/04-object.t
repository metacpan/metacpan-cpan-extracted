#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Test::Ping;

my $ping_object = Test::Ping->_ping_object;

is( ref $ping_object, 'Net::Ping', 'Got object: ' . ref $ping_object );
