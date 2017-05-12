#!perl

use strict;
use warnings;
use Test::UsedModules;

use Test::More;

my @expected = qw/all_used_modules_ok used_modules_ok/;
is_deeply \@Test::UsedModules::EXPORT, \@expected, 'export ok';

done_testing;
