#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# A stand-in for Time::Keeper's table: a packed buffer whose first member
# is an int, which is all the version check can see. Time::Keeper itself
# is loaded as usual; only its _abi_ptr is replaced.

use Time::Keeper::Business;

our $table;
our $asked = 0;
{
    no warnings 'redefine';
    *Time::Keeper::_abi_ptr = sub {
        $asked++;
        die "no table today\n" unless defined $table;
        return unpack(length(pack('p', '')) == 8 ? 'Q' : 'L', pack('p', $table));
    };
}

my $built = Time::Keeper::Business::_abi_built();
Time::Keeper::Business::_abi_forget();
is(Time::Keeper::Business::_abi_resolved(), 0, 'the table is let go');

$table = pack('i', $built - 1);
ok(!eval { Time::Keeper::Business::_abi_version(); 1 }, 'a table older than the one needed is refused');
like($@, qr/^Time::Keeper::Business needs Time::Keeper 0\.05 or later \(have \Q$Time::Keeper::VERSION\E\): its table is at version ${\ ($built - 1)} and version $built is needed/,
     'saying which version it needs, which it found, and the core installed');
is(Time::Keeper::Business::_abi_resolved(), 0, 'and it is not kept');

$table = undef;
{
    local $@ = 'left alone';
    ok(!eval { Time::Keeper::Business::_abi_version(); 1 }, 'a core whose table cannot be fetched is refused');
    like($@, qr/^Time::Keeper::Business needs Time::Keeper 0\.05 or later: no table today/,
         'with the reason the fetch gave');
}
is(Time::Keeper::Business::_abi_resolved(), 0, 'and nothing is kept');
{
    local $@ = 'left alone';
    eval { Time::Keeper::Business::_abi_version() };
    isnt($@, 'left alone', 'the refusal is in $@');
}

$table = pack('i', $built + 1);
is(Time::Keeper::Business::_abi_version(), $built + 1, 'a later table is taken');
is(Time::Keeper::Business::_abi_resolved(), 1, 'and kept');

$asked = 0;
is(Time::Keeper::Business::_abi_version(), $built + 1, 'asked again, it gives the table it kept');
is(Time::Keeper::Business::_abi_version(), $built + 1, 'and again');
is($asked, 0, 'without asking the core for it again');

Time::Keeper::Business::_abi_forget();
$table = pack('i', $built);
is(Time::Keeper::Business::_abi_version(), $built, 'a table at exactly the version needed is taken');

is($built, 2, 'the version it needs is 2');
cmp_ok(Time::Keeper::Business::_abi_header(), '>=', 2, 'built against a header at version 2 or later');

done_testing;
