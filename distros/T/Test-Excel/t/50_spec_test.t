#!/usr/bin/env perl

use strict; use warnings;

use Test::More;
use Test::Excel;
use File::Spec::Functions;

ok compare_excel(
   catfile('t', 'got-4.xls'),
   catfile('t', 'exp-4.xls'),
   { tolerance       => 10**-12,
     sheet_tolerance => 0.20,
     spec            => catfile('t', 'spec-1.txt'),
   });

ok compare_excel(
   catfile('t', 'got-5.xls'),
   catfile('t', 'exp-5.xls'),
   { tolerance       => 10**-12,
     sheet_tolerance => 0.20,
     spec            => catfile('t', 'spec-2.txt')
   });

ok compare_excel(
   catfile('t', 'got-4.xls'),
   catfile('t', 'exp-4.xls'),
   { tolerance       => 10**-12,
     sheet_tolerance => 0.20,
     spec            => catfile('t', 'spec-1.txt')
   });

ok compare_excel(
   catfile('t', 'got-5.xls'),
   catfile('t', 'exp-5.xls'),
   { tolerance       => 10**-12,
     sheet_tolerance => 0.20,
     spec            => catfile('t', 'spec-2.txt')
   });

ok compare_excel(
   catfile('t', 'got-6.xls'),
   catfile('t', 'exp-6.xls'),
   { sheet           => 'MySheet2|MySheet3',
     tolerance       => 10**-12,
     sheet_tolerance => 0.20
   });

ok compare_excel(
   catfile('t', 'got-9.xls'),
   catfile('t', 'exp-9.xls'),
   { spec => catfile('t', 'spec-4.txt') });

ok !compare_excel(
   catfile('t', 'got-10.xls'),
   catfile('t', 'exp-10.xls'),
   { spec => catfile('t', 'spec-4.txt') });

eval
{
    compare_excel(
        catfile('t', 'got-5.xls'),
        catfile('t', 'exp-5.xls'),
        { tolerance => 10**-12, sheet_tolerance => 0.20, spec => catfile('t', 'spec-3.txt') }
    );
};
like($@, qr/ERROR: Invalid format data/);

done_testing;
