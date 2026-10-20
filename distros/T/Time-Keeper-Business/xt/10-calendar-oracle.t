#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Author test: calendar rules against a walk of every day from 1900 to 2100
# through Time::Keeper's own methods (in_calendar, month_code, day), which
# the core's plan two checked against ICU. What is under test here is this
# dist's month lookup and its search of the calendar years touching a
# Gregorian year, not the calendars themselves.

use Time::Keeper;
use Time::Keeper::Business;

my $R = 'Time::Keeper::Business::Rule';
my @cals = qw(hebrew islamic-umalqura islamic-civil chinese dangi persian coptic ethiopic indian);
my ($Y0, $Y1) = (1900, 2100);
srand($ENV{TKB_SEED} // 20261019);

my ($rules, $years, $bad) = (0, 0, 0);
for my $cal (@cals) {
    my (%fixed, %month_days);
    my $d = Time::Keeper->new(year => $Y0, month => 1, day => 1, hour => 12, zone => 'UTC');
    my $end = Time::Keeper->new(year => $Y1, month => 12, day => 31, hour => 12, zone => 'UTC');
    while ($d <= $end) {
        my $c = $d->in_calendar($cal);
        my ($code, $day) = ($c->month_code, $c->day);
        push @{ $fixed{$code}{$day}{ $d->year } }, $d->ymd;
        push @{ $month_days{ $c->year . ":$code" } }, [ $d->ymd, $d->day_of_week, $d->year ];
        $d = $d->plus(days => 1);
    }
    my @codes = sort keys %fixed;
    for (1 .. 25) {
        my $code = $codes[ int rand @codes ];
        my $day = 1 + int rand 30;
        my $rule = $R->fixed(calendar => $cal, month_code => $code, day => $day);
        $rules++;
        for my $y ($Y0 + 1 .. $Y1 - 1) {
            my $got = join ' ', map { "$_->[0]" } $rule->holidays(year => $y);
            my $want = join ' ', @{ $fixed{$code}{$day}{$y} || [] };
            $years++;
            next if $got eq $want;
            $bad++;
            diag("$cal $code $day $y: got '$got' want '$want'") if $bad <= 5;
        }
    }
    my %nth;
    for my $key (keys %month_days) {
        my ($cy, $code) = split /:/, $key;
        my $days = $month_days{$key};
        for my $w (1 .. 7) {
            my @hits = grep { $_->[1] == $w } @$days;
            for my $n (1 .. 5) { push @{ $nth{$code}{$w}{$n}{ $hits[$n - 1][2] } }, $hits[$n - 1][0] if $hits[$n - 1] }
            push @{ $nth{$code}{$w}{-1}{ $hits[-1][2] } }, $hits[-1][0] if @hits;
        }
    }
    for (1 .. 10) {
        my $code = $codes[ int rand @codes ];
        my ($w, $n) = (1 + int rand 7, (-1, 1 .. 5)[ int rand 6 ]);
        my $rule = $R->nth(calendar => $cal, month_code => $code, day_of_week => $w, n => $n);
        $rules++;
        for my $y ($Y0 + 1 .. $Y1 - 1) {
            my $got = join ' ', map { "$_->[0]" } $rule->holidays(year => $y);
            my $want = join ' ', sort @{ $nth{$code}{$w}{$n}{$y} || [] };
            $years++;
            next if $got eq $want;
            $bad++;
            diag("$cal nth $code w$w n$n $y: got '$got' want '$want'") if $bad <= 5;
        }
    }
}
is($bad, 0, "$rules calendar rules over $years rule-years agree with a walk of every day in the core");

done_testing;
