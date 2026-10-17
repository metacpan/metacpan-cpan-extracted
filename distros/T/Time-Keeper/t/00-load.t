#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use_ok('Time::Keeper') or BAIL_OUT('Time::Keeper does not load');

ok(defined $Time::Keeper::VERSION, 'it has a version');
like($Time::Keeper::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

is(Time::Keeper::_int64_probe(), '4611686018427387905',
   '64-bit integers are 64 bits in the C, whatever the IV size');

ok(!$INC{'Time/Keeper/Zone.pm'}, 'loading it does not load the zones');
is(Time::Keeper::_zone_abi_resolved(), 0, 'nor look for their table');

cmp_ok(Time::Keeper::_zone_abi_built(), '>=', 1,
       'it was compiled against a version of the zones\' table');

{
    local $@ = 'left alone';
    my $found = Time::Keeper::_zone_abi_version();
    is($@, 'left alone', 'finding the table leaves the caller\'s $@ alone');
    ok($INC{'Time/Keeper/Zone.pm'}, 'asking for the table loads the zones');
    cmp_ok($found, '>=', Time::Keeper::_zone_abi_built(),
           'and the table found is the version built against or a later one');
    is($found, Time::Keeper::Zone::_abi_version(), 'which is the table the zones say they have');
}

is(Time::Keeper::_zone_abi_resolved(), 1, 'the table is kept once found');

diag("Testing Time::Keeper $Time::Keeper::VERSION on Time::Keeper::Zone $Time::Keeper::Zone::VERSION, Perl $], $^X");

done_testing;
