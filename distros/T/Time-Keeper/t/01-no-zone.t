#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Zone is hidden: the first require of it dies, as on a machine where it
# was never installed.
unshift @INC, sub {
    die "no zones here\n" if $_[1] eq 'Time/Keeper/Zone.pm';
    return;
};

use_ok('Time::Keeper') or BAIL_OUT('Time::Keeper does not load');

ok(!$INC{'Time/Keeper/Zone.pm'}, 'Time::Keeper loads without the zones');

{
    local $@ = 'left alone';
    my $ok = eval { Time::Keeper::_zone_abi_version(); 1 };
    my $err = $@;
    ok(!$ok, 'asking for the zones\' table without them dies');
    like($err, qr/^Time::Keeper needs Time::Keeper::Zone for a named time zone: no zones here/,
         'naming the missing dist and saying why it did not load');
}

{
    local $@ = 'left alone';
    eval { my $x = 1 };
    is($@, '', 'a plain eval still clears $@');
}

is(Time::Keeper::_zone_abi_resolved(), 0, 'a failed search is not remembered as found');

my $again = eval { Time::Keeper::_zone_abi_version(); 1 };
ok(!$again, 'and asking again tries again, and fails again');

done_testing;
