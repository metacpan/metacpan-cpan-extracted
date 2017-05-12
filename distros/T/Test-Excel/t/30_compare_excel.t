#!/usr/bin/perl

use strict; use warnings;

use Test::More tests => 9;
use File::Spec::Functions;

BEGIN { use_ok('Test::Excel'); }

is(compare_excel(
    catfile('t', 'hello_world.xls'),
    catfile('t', 'hello_world.xls'),
), 1);

is(compare_excel(
    catfile('t', 'got-0.xls'),
    catfile('t', 'got-0.xls'),
), 1);

is(compare_excel(
    catfile('t', 'got-0.xls'),
    catfile('t', 'exp-0.xls'),
), 0);

is(compare_excel(
    catfile('t', 'got-1.xls'),
    catfile('t', 'exp-1.xls'),
    { sheet => 'MySheet1|MySheet2', tolerance => 10**-12, sheet_tolerance => 0.20 }
), 1);

is(compare_excel(
    catfile('t', 'got-2.xls'),
    catfile('t', 'exp-2.xls'),
    { sheet => 'MySheet1|MySheet2', tolerance => 10**-12, sheet_tolerance => 0.20 }
), 1);

is(compare_excel(
    catfile('t', 'got-3.xls'),
    catfile('t', 'exp-3.xls'),
    { sheet => 'MySheet1|MySheet2', tolerance => 10**-12, sheet_tolerance => 0.20 }
), 0);

is(compare_excel(
    catfile('t', 'got-7.xls'),
    catfile('t', 'exp-7.xls'),
    { swap_check => 1, error_limit => 2, sheet => 'MySheet1|MySheet2', tolerance => 10**-12, sheet_tolerance => 0.20 }
), 1);

is(compare_excel(
    catfile('t', 'got-8.xls'),
    catfile('t', 'exp-8.xls'),
    { swap_check => 1, error_limit => 12, sheet => 'MySheet1|MySheet2', tolerance => 10**-12, sheet_tolerance => 0.20 }
), 1);
