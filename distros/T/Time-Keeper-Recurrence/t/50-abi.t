#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper::Recurrence;

# The C ABI: the table is where _abi_ptr says, it stays there, it is the
# version the header says, and every entry, called through the pointer as
# a consumer calls it, gives what it should.

my $p = Time::Keeper::Recurrence::_abi_ptr();
ok($p, 'the table has an address');
is(Time::Keeper::Recurrence::_abi_ptr(), $p, 'and the same one every time');
is(Time::Keeper::Recurrence::_abi_version(), 1, 'version 1');
my ($step, $made) = Time::Keeper::Recurrence::_abi_selftest($p);
is($step, 0, 'every entry, called through the pointer, as a consumer calls it') or diag("check $step failed");
isa_ok($made, 'Time::Keeper::Recurrence', 'what new_sv made');
is($made->rrule, 'FREQ=DAILY;COUNT=10', 'the rule the handle held');
is(scalar(() = $made->first(20)), 10, 'and it walks in Perl, after its handle was released');
is($made->zone, 'America/New_York', 'in its zone');

done_testing;
