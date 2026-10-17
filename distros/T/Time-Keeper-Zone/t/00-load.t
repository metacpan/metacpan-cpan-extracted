#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use_ok('Time::Keeper::Zone') or BAIL_OUT('Time::Keeper::Zone does not load');

ok(defined $Time::Keeper::Zone::VERSION, 'it has a version');
like($Time::Keeper::Zone::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

can_ok('Time::Keeper::Zone', qw(_abi_ptr _abi_version));

cmp_ok(Time::Keeper::Zone::_abi_version(), '>=', 1, 'the C table has a version');
cmp_ok(Time::Keeper::Zone::_abi_ptr(), '>', 0, 'and an address');
is(Time::Keeper::Zone::_abi_ptr(), Time::Keeper::Zone::_abi_ptr(),
   'the same address every time it is asked');

is(Time::Keeper::Zone::_int64_probe(), '4611686018427387905',
   '64-bit integers are 64 bits in the C, whatever the IV size');

diag("Testing Time::Keeper::Zone $Time::Keeper::Zone::VERSION, Perl $], $^X");

done_testing;
