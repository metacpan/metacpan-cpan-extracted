#!/usr/bin/perl

use strict; use warnings;

use Test::More tests => 6;

use Test::Excel;
use File::Spec::Functions;

is(compare_excel(
    catfile('t', 'got-4.xls'),
    catfile('t', 'exp-4.xls'),
    { tolerance => 10**-12, sheet_tolerance => 0.20, spec => catfile('t', 'spec-1.txt') }
), 1);

is(compare_excel(
    catfile('t', 'got-5.xls'),
    catfile('t', 'exp-5.xls'),
    { tolerance => 10**-12, sheet_tolerance => 0.20, spec => catfile('t', 'spec-2.txt') }
), 1);

is(compare_excel(
    catfile('t', 'got-4.xls'),
    catfile('t', 'exp-4.xls'),
    { tolerance => 10**-12, sheet_tolerance => 0.20, spec => catfile('t', 'spec-1.txt') }
), 1);

is(compare_excel(
    catfile('t', 'got-5.xls'),
    catfile('t', 'exp-5.xls'),
    { tolerance => 10**-12, sheet_tolerance => 0.20, spec => catfile('t', 'spec-2.txt') }
), 1);

is(compare_excel(
    catfile('t', 'got-6.xls'),
    catfile('t', 'exp-6.xls'),
    { sheet => 'MySheet2|MySheet3', tolerance => 10**-12, sheet_tolerance => 0.20 }
), 1);

eval
{
    compare_excel(
        catfile('t', 'got-5.xls'),
        catfile('t', 'exp-5.xls'),
        { tolerance => 10**-12, sheet_tolerance => 0.20, spec => catfile('t', 'spec-3.txt') }
    );
};
like($@, qr/ERROR: Invalid format data/);
