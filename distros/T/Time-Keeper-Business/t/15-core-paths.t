#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;
use Time::Keeper::Business;

# Time::Keeper 0.07's table reads and makes Dates, weekends and Durations,
# and finds a zone's next change. Every answer is the same as the method
# calls give with those entries left unused.

plan skip_all => 'built against a core header with no version 3 dates' if Time::Keeper::Business::_abi_v3_paths() < 0;
plan skip_all => 'the core table is older than version 3' if Time::Keeper::Business::_abi_version() < 3;

is(Time::Keeper::Business::_abi_v3_paths(), 1, 'the version 3 entries are used');

my $C = 'Time::Keeper::Business';
{
    package My::Date;
    our @ISA = ('Time::Keeper::Date');
}

sub answers {
    srand(20261019);
    my @out;
    my @locales = qw(en-GB ar-EG fr he);
    my $uk = $C->new(weekend => 'en-GB', holidays => [ Time::Keeper::Business::Rule->uk ]);
    my $eg = $C->new(weekend => 'ar-EG', holidays => [ '2026-10-06', { '--01-07' => 'Christmas' } ]);
    my %h = map { $_ => $C->new(zone => 'America/New_York', hours => ['22:00-06:00', '09:00-12:00'], weekend => [], reckon => $_) } qw(wall elapsed);
    for my $i (1 .. 2000) {
        my $days = 20000 + int rand 2000;
        my $loc = $locales[$i % 4];
        my $d = ($i % 7 ? 'Time::Keeper::Date' : 'My::Date')->from_epoch_days($days, locale => $loc);
        my $e = Time::Keeper::Date->from_epoch_days($days + int rand 90, locale => $loc);
        my $n = int(rand 41) - 20;
        for my $s ($uk, $eg) {
            my $p = $s->plus_business_days($d, $n);
            push @out, join ' ', $s->is_business_day($d), map({ ref($_) . " $_ " . $_->locale } $s->next_business_day($d), $p),
                $s->business_days_between($d, $e);
        }
        my $ym = Time::Keeper::YearMonth->new(year => $d->year, month => $d->month, locale => $loc);
        push @out, join ' ', map { ref($_) . " $_ " . $_->locale } $uk->nth_business_day($ym, 1 + $i % 5), $uk->last_business_day($ym);
        my $t = Time::Keeper->from_epoch($days * 86400 + int rand 86400, zone => 'America/New_York');
        my $u = $t->plus(seconds => int(rand(30 * 86400)) - 10 * 86400);
        push @out, join ' ', map { $h{$_}->business_hours_between($t, $u) . '', $h{$_}->plus_business_hours($t, hours => $i % 50) . '' } qw(wall elapsed);
        push @out, join ' ', map { "$_" } $h{wall}->business_hours_on($d) ? map { @$_ } $h{wall}->business_hours_on($d) : ();
    }
    push @out, join ' ', map { "$_->[0] $_->[1]" } $uk->holidays(year => 2026);
    my $it = $eg->iterate_business_days(Time::Keeper::Date->from_epoch_days(20700, locale => 'ar-EG'));
    push @out, join ' ', map { my $x = $it->(); ref($x) . " $x " . $x->locale } 1 .. 20;
    push @out, join ' ', map { $C->new(weekend => $_)->is_business_day(Time::Keeper::Date->new(year => 2026, month => 10, day => 16)) } qw(en-GB ar-EG he-IL fa-IR en-IN);
    return \@out;
}

my $on = answers();
is(Time::Keeper::Business::_abi_v3_paths(0), 0, 'the version 3 entries can be left unused');
my $off = answers();
Time::Keeper::Business::_abi_v3_paths(1);
is(scalar(@$on), scalar(@$off), 'as many answers both ways (' . scalar(@$on) . ')');
my @diff = grep { $on->[$_] ne $off->[$_] } 0 .. $#$on;
ok(!@diff, 'and every one the same: Dates, YearMonths, a subclass, weekends, holidays, the iterator, Durations and elapsed time')
    or diag(join "\n", map { "on:  $on->[$_]\noff: $off->[$_]" } @diff[0 .. ($#diff < 4 ? $#diff : 4)]);

done_testing;
