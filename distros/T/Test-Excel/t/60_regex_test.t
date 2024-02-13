#!/usr/bin/env perl

use strict; use warnings;

use Test::More;
use Test::Excel;
use File::Spec::Functions;

ok compare_excel(
   catfile('t', 'got-11.xls'),
   catfile('t', 'exp-11.xls'),
   { spec => catfile('t', 'spec-5.txt') });

ok compare_excel(
   catfile('t', 'got-11.xls'),
   catfile('t', 'exp-11.xls'),
   { spec => catfile('t', 'spec-5.txt') });

ok compare_excel(
   catfile('t', 'got-11.xls'),
   catfile('t', 'exp-11.xls'),
   { spec => catfile('t', 'spec-6.txt') });

ok !compare_excel(
   catfile('t', 'got-11.xls'),
   catfile('t', 'exp-11.xls'),
   { spec => catfile('t', 'spec-7.txt') });

ok !compare_excel(
   catfile('t', 'got-12.xls'),
   catfile('t', 'exp-12.xls'),
   { spec => catfile('t', 'spec-5.txt') });

done_testing;
