#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Local qw(timegm);

use Time::Keeper;

my $K = 'Time::Keeper';
sub ny { $K->new(@_, zone => 'America/New_York') }

# New York, 1 November 2026: the clocks go back from 02:00 EDT to 01:00 EST.
my $t = ny(year => 2026, month => 11, day => 1, hour => 1, minute => 30, second => 7, nanosecond => 5);
ok($t->is_ambiguous, '01:30 on the fall-back night is ambiguous');
is($t->offset, -14400, 'and the default reading is the earlier, EDT');
my $o = $t->other_reading;
ok(defined $o, 'other_reading gives a value');
is($o->offset, -18000, 'at the other offset, EST');
is($o->epoch - $t->epoch, 3600, 'an hour later');
is($o->strftime('%T'), $t->strftime('%T'), 'with the same wall clock');
is($o->nanosecond, 5, 'and the same nanosecond');
ok($o->is_ambiguous, 'it is ambiguous too');
is($o->other_reading->epoch, $t->epoch, 'and its other reading is the first');
is($o->zone_name, 'America/New_York', 'in the same zone');

my $later = ny(year => 2026, month => 11, day => 1, hour => 1, minute => 30, second => 7, overlap => 'later');
is($later->epoch, $o->epoch, 'overlap => later is the other reading');
is($later->other_reading->offset, -14400, 'whose other reading is EDT');

my $before = ny(year => 2026, month => 11, day => 1, hour => 0, minute => 59, second => 59);
ok(!$before->is_ambiguous, '00:59:59 is not ambiguous');
ok(!defined $before->other_reading, 'and has no other reading');
ok(!ny(year => 2026, month => 11, day => 1, hour => 2)->is_ambiguous, 'nor 02:00, after it');
ok(ny(year => 2026, month => 11, day => 1, hour => 1, minute => 59, second => 59)->is_ambiguous, '01:59:59 is');

# Made from an epoch, the same instant is as ambiguous.
my $e = $K->from_epoch($t->epoch, zone => 'America/New_York');
ok($e->is_ambiguous, 'a value from an epoch is ambiguous by its wall clock');
is($e->other_reading->epoch, $o->epoch, 'with the same other reading');

# 8 March 2026: the clocks go forward from 02:00 EST to 03:00 EDT.
ok(!eval { ny(year => 2026, month => 3, day => 8, hour => 2, minute => 30); 1 }, '02:30 on the spring-forward night dies');
my $g = ny(year => 2026, month => 3, day => 8, hour => 2, minute => 30, gap => 'forward');
ok(!$g->is_ambiguous, 'taken forward, it is not ambiguous');
ok(!defined $g->other_reading, 'and has no other reading');

# Transitions as values.
my $jan = ny(year => 2026);
my $n = $jan->next_transition;
is("$n", '2026-03-08T03:00:00-04:00', 'next_transition from January is 8 March, 07:00Z');
is($n->epoch, timegm(0, 0, 7, 8, 2, 2026), 'at 2026-03-08T07:00:00Z');
is($n->zone_name, 'America/New_York', 'in the same zone');
is($n->previous_transition->rfc3339, '2025-11-02T01:00:00-05:00', 'its previous_transition is 2 November 2025');
is($n->next_transition->rfc3339, '2026-11-01T01:00:00-05:00', 'and its next, 1 November');
is($n->next_transition->previous_transition->epoch, $n->epoch, 'which steps back to it: strictly before');
my $half = $K->from_epoch($n->epoch + 0.5, zone => 'America/New_York');
is($half->previous_transition->epoch, $n->epoch, 'half a second into a transition, it is the previous one');
is($K->from_epoch($n->epoch, zone => 'America/New_York')->previous_transition->epoch, timegm(0, 0, 6, 2, 10, 2025),
   'at the transition exactly, the previous is the one before');

# Zone and locale travel with the value.
my $us = $K->new(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'US/Eastern', locale => 'fr');
is($us->other_reading->zone_name, 'US/Eastern', 'other_reading keeps a link\'s name');
is($us->other_reading->locale, 'fr', 'and the locale');
is($us->next_transition->zone_name, 'US/Eastern', 'so does next_transition');
is($us->next_transition->locale, 'fr', 'and its locale');

# The zones that never change.
for my $z ('UTC', '+05:30', 'floating') {
    my $v = $K->new(year => 2026, month => 7, zone => $z);
    ok(!defined $v->next_transition, "$z: no next transition");
    ok(!defined $v->previous_transition, "$z: no previous transition");
    ok(!$v->is_ambiguous, "$z: never ambiguous");
    ok(!defined $v->other_reading, "$z: no other reading");
    is($v->dst_offset, 0, "$z: dst_offset 0");
}
is($K->new(year => 2026, zone => '+05:30')->standard_offset, 19800, 'a fixed zone\'s standard offset is its offset');
is($K->new(year => 2026, zone => 'UTC')->standard_offset, 0, 'UTC\'s is 0');
ok(!defined $K->new(year => 2026, zone => 'Asia/Tokyo')->next_transition, 'Tokyo has no next transition');
is($K->new(year => 2026, zone => 'Asia/Tokyo')->previous_transition->year, 1951, 'its previous is in 1951');

# Standard and daylight offsets.
my $jul = $K->new(year => 2026, month => 7, zone => 'Europe/London');
is($jul->standard_offset, 0, 'London in July: standard offset 0');
is($jul->dst_offset, 3600, 'dst_offset 3600');
is($K->new(year => 2026, month => 1, zone => 'Europe/London')->dst_offset, 0, 'in January 0');
my $lh = $K->new(year => 2026, month => 1, zone => 'Australia/Lord_Howe');
is($lh->offset, 39600, 'Lord Howe in January is +11:00');
is($lh->standard_offset, 37800, 'its standard time +10:30');
is($lh->dst_offset, 1800, 'so dst_offset is 1800');
my $dub = $K->new(year => 2026, month => 1, zone => 'Europe/Dublin');
is($dub->standard_offset, 3600, 'Dublin\'s standard time is +01:00');
is($dub->dst_offset, -3600, 'and its winter GMT a dst_offset of -3600');
is($K->new(year => 2026, month => 7, zone => 'Europe/Dublin')->dst_offset, 0, 'its summer IST is standard');

done_testing;
