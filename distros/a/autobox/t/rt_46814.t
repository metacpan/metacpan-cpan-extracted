#!/usr/bin/env perl

# Thanks to Tye McQueen for this test case and rationale
# https://rt.cpan.org/Ticket/Display.html?id=46814

use strict;
use warnings;

use Test::More tests => 7;

use autobox::universal 'type';

my $f = 3.1415927;
is type($f), 'FLOAT', 'Pi == FLOAT';
is type(0 & $f), 'INTEGER', '0 & Pi == INTEGER';
is type($f), 'FLOAT', 'Pi is still a FLOAT';

my $i = 42;
is type($i), 'INTEGER', '42 == INTEGER';
is type($i / 3), 'FLOAT', '42 / 3 == FLOAT';
is type(int($i / 3)), 'INTEGER', 'int(42 / 3) == INTEGER';
is type($i), 'INTEGER', '42 is still an INTEGER'; # XXX D'oh! This used to return FLOAT
