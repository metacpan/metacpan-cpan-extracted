#!perl

# this is an example of Test::Ping usage

use strict;
use warnings;

use Test::More tests => 3;
use Test::Ping;

ping_ok( 'google.com', 'Can ping google.com!' );
ping_not_ok( 'googblelez.com', 'However, googblelez.com is down' );

$Test::Ping::Timeout = 2;

ping_ok( 'yahoo.com', 'Yahoo! answered in 2 secs or less' );

