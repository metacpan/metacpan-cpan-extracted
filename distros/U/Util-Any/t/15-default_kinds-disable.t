#!perl -T

use Test::More;
use lib qw(t/lib/);
use UtilDefaultKinds -list => [];

ok(not(defined &uniq), '-list is disabled');
ok(not(defined &isweak), 'isweak is not defined');
ok(defined &camelize, 'camelize is in -string');

done_testing;
