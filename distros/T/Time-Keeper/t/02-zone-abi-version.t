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

done_testing;
