#!/usr/bin/env perl

use strict; use warnings;

use Test::More;
use File::Spec::Functions;

BEGIN { use_ok('Test::Excel'); }

cmp_excel(
    catfile('t', 'hello_world.xls'),
    catfile('t', 'hello_world.xls'),
    {}, 'Our Excels were essentially the same.');

cmp_excel(
    catfile('t', 'hello_world.xlsx'),
    catfile('t', 'hello_world.xlsx'),
    {}, 'Our Excels were essentially the same.');

cmp_excel_ok(
    catfile('t', 'got-0.xls'),
    catfile('t', 'got-0.xls'),
    {}, 'Our Excels were essentially the same.');

cmp_excel_not_ok(
    catfile('t', 'got-0.xls'),
    catfile('t', 'exp-0.xls'),
    {}, 'Our Excels were NOT essentially the same.');

cmp_excel(
    catfile('t', 'got-7.xls'),
    catfile('t', 'exp-7.xls'),
    { swap_check      => 1,
      error_limit     => 2,
      sheet           => 'MySheet1|MySheet2',
      tolerance       => 10**-12,
      sheet_tolerance => 0.20,
    }, 'OK');

cmp_excel(
    catfile('t','got-4.xls'),
    catfile('t','exp-4.xls'),
    { tolerance       => 10**-12,
      sheet_tolerance => 0.20,
      spec            => catfile('t', 'spec-1.txt'),
    });

cmp_excel(
    catfile('t', 'got-5.xls'),
    catfile('t', 'exp-5.xls'),
    { tolerance       => 10**-12,
      sheet_tolerance => 0.20,
      spec            => catfile('t', 'spec-2.txt'),
    });

cmp_excel(
    catfile('t', 'got-4.xls'),
    catfile('t', 'exp-4.xls'),
    { tolerance       => 10**-12,
      sheet_tolerance => 0.20,
      spec            => catfile('t', 'spec-1.txt'),
    });

cmp_excel(
    catfile('t', 'got-5.xls'),
    catfile('t', 'exp-5.xls'),
    { tolerance       => 10**-12,
      sheet_tolerance => 0.20,
      spec            => catfile('t', 'spec-2.txt'),
    });

done_testing;
