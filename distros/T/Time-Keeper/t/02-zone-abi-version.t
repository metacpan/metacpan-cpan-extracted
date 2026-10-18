#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# A stand-in for Time::Keeper::Zone whose table is a packed buffer: the
# table's first member is its version, an int, so a buffer holding one int
# is a table of that version as far as the version check can see. Marking
# the module loaded makes the require of it a no-op.

our $table;
our $asked = 0;

$INC{'Time/Keeper/Zone.pm'} = __FILE__;
{
    no warnings 'once';
    *Time::Keeper::Zone::_abi_ptr = sub {
        $asked++;
        return unpack(length(pack('p', '')) == 8 ? 'Q' : 'L', pack('p', $table));
    };
}

use_ok('Time::Keeper') or BAIL_OUT('Time::Keeper does not load');

my $built = Time::Keeper::_zone_abi_built();

$table = pack('i', $built - 1);
ok(!eval { Time::Keeper::_zone_abi_version(); 1 }, 'a table older than the one built against is refused');
like($@, qr/^Time::Keeper needs Time::Keeper::Zone's table at version $built or later, and found ${\ ($built - 1)}/,
     'saying which version it needs and which it found');
is(Time::Keeper::_zone_abi_resolved(), 0, 'and it is not kept');

$table = pack('i', $built + 1);
is(Time::Keeper::_zone_abi_version(), $built + 1, 'a later table is taken');
is(Time::Keeper::_zone_abi_resolved(), 1, 'and kept');

$asked = 0;
is(Time::Keeper::_zone_abi_version(), $built + 1, 'asked again, it gives the table it kept');
is(Time::Keeper::_zone_abi_version(), $built + 1, 'and again');
is($asked, 0, 'without asking the zones for it again');

# It needs the version whose entries it calls, version 1's, whichever Zone
# header it was built against: a Zone of 0.01 or 0.02 still serves it.
is($built, 1, 'the version it needs is 1');
cmp_ok(Time::Keeper::_zone_abi_header(), '>=', 2, 'built against a header at version 2 or later');
for my $v (1, 2) {
    Time::Keeper::_zone_abi_forget();
    $table = pack('i', $v);
    is(Time::Keeper::_zone_abi_version(), $v, "a table at version $v is taken");
}

# The methods of Phase 05 call version 2's entries, and say so when the
# table is older.
Time::Keeper::_zone_abi_forget();
$table = pack('i', 1);
{
    no warnings 'once';
    local $Time::Keeper::Zone::VERSION = '0.02';
    ok(!eval { Time::Keeper::_zone_abi_v2_version(); 1 }, 'a version 1 table is refused by the version 2 gate');
    like($@, qr/^Time::Keeper->_zone_abi_v2_version needs Time::Keeper::Zone 0\.03 or later \(have 0\.02\)/,
         'naming the method and the Zone installed');
}
Time::Keeper::_zone_abi_forget();
$table = pack('i', 2);
is(Time::Keeper::_zone_abi_v2_version(), 2, 'and a version 2 table passes it');

done_testing;
