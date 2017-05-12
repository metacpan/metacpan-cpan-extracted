#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More 'no_plan';
use jBilling::Client::SOAP::JavaDouble qw ( toDouble fromDouble );

#plan tests => 4;

ok( toDouble(6.56) == 6.5600000000,   'toDouble returned 6.5600000000' );
ok( toDouble(undef) == 0,             'undefined value to toDouble returns 0' );
ok( toDouble('thisisastring') == 0,             'non number passed to toDouble returns 0' );
ok( fromDouble(650.4670000000) == 650.47, 'fromDouble' );
ok( fromDouble(undef) == 0, 'undefined value to fromDouble returns 0' );
ok( fromDouble('thisisastring') == 0,             'non number passed to fromDouble returns 0' );