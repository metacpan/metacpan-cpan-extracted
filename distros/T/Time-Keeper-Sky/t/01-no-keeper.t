#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Time::Keeper is hidden: the first require of it dies, as on a machine
# where it was never installed.
unshift @INC, sub {
    die "no keeper here\n" if $_[1] eq 'Time/Keeper.pm';
    return;
};

use_ok('Time::Keeper::Sun') or BAIL_OUT('Time::Keeper::Sun does not load');

ok(!$INC{'Time/Keeper.pm'}, 'Time::Keeper::Sun loads without Time::Keeper');

{
    local $@ = 'left alone';
    my $ok = eval { Time::Keeper::Sun::_tk_abi_version(); 1 };
    my $err = $@;
    ok(!$ok, 'asking for Time::Keeper\'s table without it dies');
    like($err, qr/^Time::Keeper::Sun needs Time::Keeper: no keeper here/,
         'naming the missing dist and saying why it did not load');
}

{
    local $@ = 'left alone';
    eval { my $x = 1 };
    is($@, '', 'a plain eval still clears $@');
}

is(Time::Keeper::Sun::_tk_abi_resolved(), 0, 'a failed search is not remembered as found');

my $again = eval { Time::Keeper::Sun::_tk_abi_version(); 1 };
ok(!$again, 'and asking again tries again, and fails again');

ok(!eval { Time::Keeper::Sun::_tk_now(); 1 }, 'a call through the table dies the same way');
like($@, qr/^Time::Keeper::Sun needs Time::Keeper: no keeper here/, 'with the same reason');

done_testing;
