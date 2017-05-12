# -*- cperl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok('iCal::Parser::HTML') };

isa_ok(iCal::Parser::HTML->new, 'iCal::Parser::HTML');
