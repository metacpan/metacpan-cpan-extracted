#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Author test: the business-day arithmetic against a walker that steps a
# day at a time with Time::Keeper::Date, over random schedules.

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
srand($ENV{TKB_SEED} // 20261018);
my $base = Time::Keeper::Date->new(year => 2026, month => 1, day => 1)->epoch_days;
sub D { Time::Keeper::Date->from_epoch_days($_[0]) }

my @masks = ([6, 7], [5, 6], [7], [], [4, 5], [1 .. 6]);
my @pool;
for my $i (1 .. 12) {
    my $w = $masks[$i % @masks];
    my %w = map { $_ => 1 } @$w;
    my (@hol, @work);
    for (1 .. int(rand(60))) { push @hol, D($base + int(rand(7300)) - 3650) }
    my %hol = map { $_->epoch_days => 1 } @hol;
    for (1 .. int(rand(20))) {
        my $d = D($base + int(rand(7300)) - 3650);
        push @work, $d if $w{ $d->day_of_week } && !$hol{ $d->epoch_days };
    }
    push @pool, $C->new(weekend => $w, holidays => \@hol, working => \@work);
}

sub walk_plus {
    my ($b, $day, $n) = @_;
    my $d = $day;
    if ($n >= 0) { $d++ while !$b->is_business_day(D($d)) }
    else         { $d-- while !$b->is_business_day(D($d)) }
    my $left = abs $n;
    my $dir = $n >= 0 ? 1 : -1;
    while ($left) { $d += $dir; $left-- if $b->is_business_day(D($d)) }
    return $d;
}
sub walk_between {
    my ($b, $a, $z) = @_;
    return -walk_between($b, $z, $a) if $a > $z;
    my $n = 0;
    for my $d ($a .. $z - 1) { $n++ if $b->is_business_day(D($d)) }
    return $n;
}

my ($bad_plus, $bad_between, $n) = (0, 0, 0);
for (1 .. 20_000) {
    my $b = $pool[ int(rand @pool) ];
    my $day = $base + int(rand(7300)) - 3650;
    my $k = int(rand(1001)) - 500;
    my $got = $b->plus_business_days(D($day), $k)->epoch_days;
    my $want = walk_plus($b, $day, $k);
    $bad_plus++ if $got != $want;
    my $len = int(rand(700)) - 350;
    $bad_between++ if $b->business_days_between(D($day), D($day + $len)) != walk_between($b, $day, $day + $len);
    $n++;
}
is($bad_plus, 0, "plus_business_days agrees with the walker on $n triples");
is($bad_between, 0, "business_days_between agrees with the walker on $n pairs");

my %conv_bad;
for (1 .. 5_000) {
    my $b = $pool[ int(rand @pool) ];
    my $day = $base + int(rand(7300)) - 3650;
    next if $b->is_business_day(D($day));
    my $f = $day; $f++ while !$b->is_business_day(D($f));
    my $p = $day; $p-- while !$b->is_business_day(D($p));
    my $m = D($day)->month;
    my %want = (
        following => $f, preceding => $p,
        modified_following => (D($f)->month == $m ? $f : $p),
        modified_preceding => (D($p)->month == $m ? $p : $f),
        nearest => (($f - $day) <= ($day - $p) ? $f : $p),
    );
    for my $c (keys %want) {
        $conv_bad{$c}++ if $b->roll(D($day), convention => $c)->epoch_days != $want{$c};
    }
}
is_deeply(\%conv_bad, {}, 'every convention agrees with the walker on 5,000 closed days') or diag explain \%conv_bad;

done_testing;
