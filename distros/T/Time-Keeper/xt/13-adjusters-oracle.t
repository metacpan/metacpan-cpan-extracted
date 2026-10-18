#!perl
# The weekday adjusters and end_of against DateTime. Author only. The
# nth weekday of a month is DateTime's set(day => 1) walked on; end_of is
# DateTime's truncate, add a unit, subtract a nanosecond; all in UTC, where
# no gap can interfere. DateTime has no quarter, no round and no
# millisecond or microsecond truncation, so those are t/26's. The DateTime
# is built without nanoseconds: set_nanosecond puts its local_rd_secs a
# second out (found in plan one, Phase 08), and the fraction changes none of
# these answers.
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DateTime; 1 } or plan skip_all => 'DateTime is needed for this oracle';
}
use Time::Keeper;

my $K = 'Time::Keeper';
my $N = $ENV{TK_ORACLE_N} || 20_000;
srand($ENV{TK_SEED} || 20261017);

my %unit_add = (year => [years => 1], month => [months => 1], week => [weeks => 1], day => [days => 1],
                hour => [hours => 1], minute => [minutes => 1], second => [seconds => 1]);
my @dow_from_sunday = (7, 1, 2, 3, 4, 5, 6);
my $bad = 0;
for my $i (1 .. $N) {
    my $epoch = int(rand(2 * 2_147_483_648)) - 2_147_483_648;
    my $nsec  = int(rand(1e9));
    my $t  = $K->from_epoch($epoch)->plus(nanoseconds => $nsec);
    my $dt = DateTime->from_epoch(epoch => $epoch);
    for my $unit (sort keys %unit_add) {
        my $want = $dt->clone->truncate(to => $unit)->add(@{ $unit_add{$unit} })->subtract(nanoseconds => 1);
        my $got  = $t->end_of(to => $unit);
        next if $got->epoch == $want->epoch && $got->nanosecond == $want->nanosecond;
        $bad++;
        diag("end_of $unit of $t: got $got, DateTime " . $want->iso8601 . '.' . $want->nanosecond);
    }
    my $dow = 1 + int(rand(7));
    my $first = $dt->clone->set(day => 1);
    my @days;
    for my $d (1 .. $dt->month_length) {
        push @days, $d if $first->clone->set(day => $d)->day_of_week == $dow;
    }
    for my $n (1 .. 5, -1) {
        my $want = $n > 0 ? $days[$n - 1] : $days[-1];
        my $got = eval { $t->nth_in_month(day_of_week => $dow, n => $n)->day };
        if (defined $want ? (!defined $got || $got != $want) : defined $got) {
            $bad++;
            diag("nth_in_month $dow n=$n of $t: got " . ($got // 'death') . ', want ' . ($want // 'death'));
        }
    }
    my $next = $t->next(day_of_week => $dow);
    my $want = $dt->clone->truncate(to => 'day');
    $want->add(days => 1) until $want->day_of_week == $dow && $want > $dt->clone->truncate(to => 'day');
    unless ($next->ymd eq $want->ymd && $next->hms eq $dt->hms) {
        $bad++;
        diag("next $dow of $t: got $next, want " . $want->ymd . ' ' . $dt->hms);
    }
    my $prev = $t->previous(day_of_week => $dow);
    $want = $dt->clone->truncate(to => 'day');
    $want->subtract(days => 1) until $want->day_of_week == $dow && $want < $dt->clone->truncate(to => 'day');
    unless ($prev->ymd eq $want->ymd) {
        $bad++;
        diag("previous $dow of $t: got $prev, want " . $want->ymd);
    }
    last if $bad > 20;
}
is($bad, 0, "$N random values agree with DateTime on end_of, next, previous and the nth weekday");

done_testing;
