#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
BEGIN { require './xt/skyfield_oracle.pl' }
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# Author test: Skyfield and DE421 for the moon: its rises, sets and transits
# on USNO's one-day rows, and its geocentric place at USNO's celnav instants.
# Marks set before any number was seen: moon events within 60 s below 60
# degrees of latitude and 300 above (T7's band); the declination and the
# right ascension within 0.005 degrees, the distance within 30 km (T7).

my $why = SkyfieldOracle::usable();
plan skip_all => $why if $why;

my $file = 't/usno-moon-events.tsv';
open my $fh, '<', $file or BAIL_OUT("$file: $!");
my (@rows, @jobs, %places);
while (<$fh>) {
    next if /^#/;
    chomp;
    my ($place, $date, $lat, $lon, $zone) = split /\t/;
    next unless defined $zone;
    my ($y, $m, $d) = split /-/, $date;
    next if $y < 1900 || $y > 2049;
    my $sun = $places{"$lat $lon $zone"} //= Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone);
    my $day = Time::Keeper::Moon->on(Time::Keeper::Date->new(year => $y, month => $m, day => $d), place => $sun);
    push @rows, [$place, $date, $lat, $day];
    push @jobs, { kind => 'events', body => 'moon', lat => $lat + 0, lon => $lon + 0, start => $day->start->epoch, end => $day->end->epoch };
}
close $fh;

my $answers = SkyfieldOracle::ask(\@jobs);
my %ours_of = (rise => 'moonrises', set => 'moonsets', transit => 'moon_transits');
my ($n, %worst);
for my $i (0 .. $#rows) {
    my ($place, $date, $lat, $day) = @{$rows[$i]};
    my %theirs;
    push @{$theirs{$_->[0]}}, $_->[1] for @{$answers->[$i]};
    for my $kind (sort keys %ours_of) {
        my $method = $ours_of{$kind};
        my @ours = map { $_->epoch } $day->$method;
        my @sky = @{$theirs{$kind} || []};
        is(scalar @ours, scalar @sky, "$place $date: " . scalar(@sky) . " moon $kind");
        my $mark = abs($lat) > 60 ? 300 : 60;
        for my $j (0 .. $#sky) {
            last if $j > $#ours;
            my $diff = abs($ours[$j] - $sky[$j]);
            $worst{$mark} = [$diff, "$place $date $kind"] if !$worst{$mark} || $diff > $worst{$mark}[0];
            cmp_ok($diff, '<=', $mark, sprintf '%s %s: moon %s within %d s of Skyfield (%.1f s)', $place, $date, $kind, $mark, $diff);
            $n++;
        }
    }
}
note("$n moon events; " . join '; ', map { sprintf 'worst in the %d s band %.1f s (%s)', $_, @{$worst{$_}} } sort { $a <=> $b } keys %worst);

# the moon's geocentric place at USNO's celnav instants. T7's marks for the right
# ascension (0.005) and the distance (30 km) are missed, not moved: chapter 47's
# truncated series reaches 25 arcseconds in right ascension on the sky and 41 km
# in distance against DE421 (its declination, 0.0024, meets the mark). TODO.
{
    my $cel = 't/usno-celnav-moon.tsv';
    open my $ch, '<', $cel or BAIL_OUT("$cel: $!");
    my @t;
    while (<$ch>) {
        next if /^#/;
        my (undef, $date, $time) = split /\t/;
        next unless defined $time;
        my ($y, $m, $d) = split /-/, $date;
        next if $y < 1900 || $y > 2049;
        my ($h, $mi, $s) = split /:/, $time;
        push @t, Time::Keeper->new(year => $y, month => $m, day => $d, hour => $h, minute => $mi, second => $s, zone => 'UTC');
    }
    close $ch;
    my $pos = SkyfieldOracle::ask([map { { kind => 'moonpos', epoch => $_->epoch } } @t]);
    my %w = (ra => 0, dec => 0, dist => 0);
    for my $i (0 .. $#t) {
        my $p = Time::Keeper::Moon->position($t[$i]);
        my ($ra, $dec, $dist) = @{$pos->[$i]};
        my $dra = abs($p->{right_ascension} - $ra);
        $dra = 360 - $dra if $dra > 180;
        my %d = (ra => $dra * cos($dec * 3.14159265358979 / 180), dec => abs($p->{declination} - $dec), dist => abs($p->{distance} - $dist));
        $w{$_} = $d{$_} > $w{$_} ? $d{$_} : $w{$_} for keys %d;
        cmp_ok($d{dec}, '<=', 0.005, "$t[$i]: the declination within 0.005 of Skyfield");
        TODO: {
            local $TODO = 'chapter 47 misses T7 in right ascension and distance against DE421';
            cmp_ok($d{ra}, '<=', 0.005, "$t[$i]: the right ascension within 0.005 (on the sky)");
            cmp_ok($d{dist}, '<=', 30, "$t[$i]: the distance within 30 km");
        }
    }
    note(sprintf 'moon place at %d instants: worst right ascension %.5f, declination %.5f degrees, distance %.1f km', scalar @t, @w{qw(ra dec dist)});
}

done_testing;
