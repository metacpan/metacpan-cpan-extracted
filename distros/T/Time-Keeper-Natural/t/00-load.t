#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use_ok('Time::Keeper::Natural') or BAIL_OUT('Time::Keeper::Natural does not load');

ok(defined $Time::Keeper::Natural::VERSION, 'it has a version');
like($Time::Keeper::Natural::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');
cmp_ok($Time::Keeper::VERSION, '>=', 0.07, 'Time::Keeper is 0.07 or later, with its C interface at version 3');
ok(Time::Keeper::Locale->can('day_period_rules'), 'and has the day-period rules');
cmp_ok(Time::Keeper::Natural::_abi_version(), '>=', 3, 'Time::Keeper\'s C interface was found, at version 3 or later');

diag("Testing Time::Keeper::Natural $Time::Keeper::Natural::VERSION on Time::Keeper $Time::Keeper::VERSION, Perl $], $^X");

done_testing;
