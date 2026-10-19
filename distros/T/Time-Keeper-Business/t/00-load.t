#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use_ok('Time::Keeper::Business') or BAIL_OUT('Time::Keeper::Business does not load');

ok(defined $Time::Keeper::Business::VERSION, 'it has a version');
like($Time::Keeper::Business::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

is(Time::Keeper::Business::_int64_probe(), '4611686018427387905',
   '64-bit integers are 64 bits in the C, whatever the IV size');

ok($INC{'Time/Keeper.pm'}, 'loading it loads Time::Keeper');
ok(!$INC{'Time/Keeper/Zone.pm'}, 'but not the zones');
is(Time::Keeper::Business::_abi_resolved(), 0, 'nor does it look for the core\'s table yet');

cmp_ok(Time::Keeper::Business::_abi_built(), '>=', 2,
       'it was compiled to call version 2 of the core\'s table or later');
cmp_ok(Time::Keeper::Business::_abi_header(), '>=', Time::Keeper::Business::_abi_built(),
       'against a header at that version or later');

{
    local $@ = 'left alone';
    my $found = Time::Keeper::Business::_abi_version();
    is($@, 'left alone', 'finding the table leaves the caller\'s $@ alone');
    cmp_ok($found, '>=', Time::Keeper::Business::_abi_built(),
           'and the table found is the version needed or a later one');
    ok(!$INC{'Time/Keeper/Zone.pm'}, 'finding it still does not load the zones');
}

is(Time::Keeper::Business::_abi_resolved(), 1, 'the table is kept once found');

my $now = Time::Keeper::Business::_abi_now();
my $perl = time;
cmp_ok(abs($now - $perl), '<=', 2, 'an entry of the table works: the clock agrees with perl\'s');

diag("Testing Time::Keeper::Business $Time::Keeper::Business::VERSION on Time::Keeper $Time::Keeper::VERSION, Perl $], $^X");

done_testing;
