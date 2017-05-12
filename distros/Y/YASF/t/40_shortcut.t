#!/usr/bin/perl

# Basic tests on the "YASF" shortcut

use 5.008;
use strict;
use warnings;

use Test::More;

use YASF 'YASF';

plan tests => 2;

my $str = YASF '1={one} 2={two} 3={three}';

isa_ok($str, 'YASF', 'Proper type returned');
is(YASF('1={one}') % { one => 1 }, '1=1', 'Throw-away object');

exit;
