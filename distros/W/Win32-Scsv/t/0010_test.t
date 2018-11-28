use strict;
use warnings;

use Test::More tests => 13;

use_ok('Win32::Scsv', qw(XLRef));

is(XLRef(   1,   1), 'A1',   'XLRef Test 01');
is(XLRef(  28,  22), 'AB22', 'XLRef Test 02');
is(XLRef(   2, 456), 'B456', 'XLRef Test 03');
is(XLRef(  30),      'AD',   'XLRef Test 04');
is(XLRef( 701,   1), 'ZY1',  'XLRef Test 05 - Big column numbers');
is(XLRef( 702,   1), 'ZZ1',  'XLRef Test 06 - Big column numbers');
is(XLRef( 703,   1), 'AAA1', 'XLRef Test 07 - Big column numbers');
is(XLRef( 704,   1), 'AAB1', 'XLRef Test 08 - Big column numbers');
is(XLRef(1377,   1), 'AZY1', 'XLRef Test 09 - Big column numbers');
is(XLRef(1378,   1), 'AZZ1', 'XLRef Test 10 - Big column numbers');
is(XLRef(1379,   1), 'BAA1', 'XLRef Test 11 - Big column numbers');
is(XLRef(1380,   1), 'BAB1', 'XLRef Test 12 - Big column numbers');
