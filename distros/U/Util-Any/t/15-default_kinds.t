#!perl -T

use strict;
use warnings;

use Test::More;
use lib qw(t/lib/);
use UtilDefaultKinds;

ok(defined &uniq, 'uniq is in -list');
ok(defined &camelize, 'camelize is in -string');
ok(not(defined &isweak), 'isweak is not in -list and -string');

done_testing;