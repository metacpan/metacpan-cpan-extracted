#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Time::Keeper with a Time::Keeper::Zone of 0.02: a table whose version is
# 1. The real Zone's table is copied into a string and its version patched
# back to 1, so the old entries work and the new ones are not there. The
# copy lives for the life of the process, as the core keeps the pointer.

use Time::Keeper::Zone;

our $copy;
{
    my $ptr = Time::Keeper::Zone::_abi_ptr();
    my $psize = length pack('p', '');
    $copy = unpack("P" . (16 * $psize), pack('J', $ptr));   # an int (padded) and fifteen pointers
    substr($copy, 0, length pack('i', 0)) = pack('i', 1);
    no warnings 'redefine', 'once';
    *Time::Keeper::Zone::_abi_ptr = sub { unpack('J', pack('P', $copy)) };
    $Time::Keeper::Zone::VERSION = '0.02';
}

use_ok('Time::Keeper') or BAIL_OUT('Time::Keeper does not load');

my $K = 'Time::Keeper';
my $t = $K->new(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York');
is(Time::Keeper::_zone_abi_version(), 1, 'the table the core found is at version 1');
is($t->offset, -14400, 'the old methods still work: offset');
is($t->zone_name, 'America/New_York', 'zone_name');
is($t->zone_abbr, 'EDT', 'zone_abbr');
is($t->in_zone('Europe/London')->hour, 5, 'in_zone');
is($K->new(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York',
           overlap => 'later')->offset, -18000, 'and overlap => later');

for my $m (qw(next_transition previous_transition is_ambiguous other_reading standard_offset dst_offset)) {
    ok(!eval { $t->$m; 1 }, "$m dies");
    like($@, qr/^Time::Keeper->\Q$m\E needs Time::Keeper::Zone 0\.03 or later \(have 0\.02\)/, 'naming itself and the Zone installed');
}

for my $z ('UTC', '+01:00', 'floating') {
    my $v = $K->new(year => 2026, zone => $z);
    ok(eval { !defined $v->next_transition && !$v->is_ambiguous && !defined $v->other_reading
              && defined $v->standard_offset && $v->dst_offset == 0 }, "$z needs no Zone for them") or diag $@;
}

done_testing;
