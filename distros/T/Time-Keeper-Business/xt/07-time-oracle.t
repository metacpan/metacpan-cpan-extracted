#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Author test: the business-time arithmetic against a walker that sums
# spans from business_hours_on, over random schedules in zones without
# a clock change (so the wall clock and the epoch agree), and over
# schedules reckoned elapsed in zones that change, where the epoch is the
# reckoning.

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
srand($ENV{TKB_SEED} // 20261018);
my $base = Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC')->epoch;

my @pool;
for my $i (1 .. 12) {
    my @spans = $i % 4 == 0 ? ('09:00-12:30', '13:30-17:30') : $i % 4 == 1 ? ('08:00-16:00') : $i % 4 == 2 ? ('00:00-24:00') : ('07:00-12:00', '21:00-05:00');
    my %hours = (default => [@spans]);
    $hours{fri} = ['09:00-13:00'] if $i % 2;
    my @hol = map { Time::Keeper::Date->from_epoch_days(20454 + int(rand(1500))) } 1 .. int(rand(30));
    for (1 .. int(rand(6))) {
        my $d = Time::Keeper::Date->from_epoch_days(20454 + int(rand(1500)));
        $hours{"$d"} = rand() < 0.3 ? [] : ['10:00-11:00'];
    }
    push @pool, $C->new(zone => ($i % 2 ? 'UTC' : 'Asia/Tokyo'), hours => \%hours, holidays => \@hol, weekend => ($i % 4 == 0 ? [5, 6] : [6, 7]));
    push @pool, $C->new(zone => ($i % 2 ? 'America/New_York' : 'Europe/London'), hours => \%hours, holidays => \@hol, weekend => ($i % 4 == 0 ? [5, 6] : [6, 7]), reckon => 'elapsed');
}

sub T { Time::Keeper->from_epoch($_[0], zone => 'UTC') }

# business seconds between two epochs, summing the spans of each day
sub walk_between {
    my ($b, $a, $z) = @_;
    return -walk_between($b, $z, $a) if $a > $z;
    my $total = 0;
    my $day = $b->next_open(T($a - 86400 * 2))->to_date;
    $day = T($a)->in_zone($b->zone)->to_date->plus(days => -1);
    my $end = T($z)->in_zone($b->zone)->to_date->plus(days => 1);
    while ($day <= $end) {
        for my $span ($b->business_hours_on($day)) {
            my ($o, $c) = ($span->[0]->epoch, $span->[1]->epoch);
            my $lo = $o > $a ? $o : $a;
            my $hi = $c < $z ? $c : $z;
            $total += $hi - $lo if $hi > $lo;
        }
        $day = $day->plus(days => 1);
    }
    return $total;
}

# the epoch that many business seconds after an epoch, consuming spans
sub walk_plus {
    my ($b, $a, $n) = @_;
    my $t = $b->next_open(T($a))->epoch;
    return $t if $n == 0;
    my $day = T($t)->in_zone($b->zone)->to_date->plus(days => -1);
    while (1) {
        for my $span ($b->business_hours_on($day)) {
            my ($o, $c) = ($span->[0]->epoch, $span->[1]->epoch);
            next if $c <= $t;
            my $lo = $o > $t ? $o : $t;
            if ($n <= $c - $lo) { return $lo + $n }
            $n -= $c - $lo;
        }
        $day = $day->plus(days => 1);
    }
}

my ($bad_between, $bad_plus, $n) = (0, 0, 0);
for (1 .. 5000) {
    my $b = $pool[ int(rand @pool) ];
    my $a = $base + int(rand(86400 * 700));
    my $len = int(rand(86400 * 60)) - 86400 * 20;
    my $got = $b->business_hours_between(T($a), T($a + $len))->total('seconds');
    my $want = walk_between($b, $a, $a + $len);
    if ($got != $want) { $bad_between++; diag("between: $b from $a len $len got $got want $want") if $bad_between <= 3 }
    my $amount = int(rand(3600 * 40));
    my $got2 = $b->plus_business_hours(T($a), seconds => $amount)->epoch;
    my $want2 = walk_plus($b, $a, $amount);
    if ($got2 != $want2) { $bad_plus++; diag("plus: $b from $a amount $amount got $got2 want $want2") if $bad_plus <= 3 }
    $n++;
}
is($bad_between, 0, "business_hours_between agrees with the span walker on $n pairs");
is($bad_plus, 0, "plus_business_hours agrees with the span walker on $n moments");

done_testing;
