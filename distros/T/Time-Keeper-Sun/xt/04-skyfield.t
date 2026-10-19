#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
BEGIN { require './xt/skyfield_oracle.pl' }
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# Author test: Skyfield and the JPL ephemeris DE421 (1900 to 2050) as the
# oracle to the second, for the sun's events on USNO's one-day rows, the
# seasons and the moon's phases. Set TKS_SKYFIELD to a python with skyfield
# and TKS_SKYFIELD_DATA to a directory holding de421.bsp. The marks were set
# in plan_time_keeper_sun_2/05-skyfield.md before any number was seen:
# sunrise, sunset, transits and civil twilight within 30 s below 60 degrees
# of latitude (0.01's bands above: 120 s, and 1800 s within a degree of a
# pole), the seasons within 51 s, the phases within 30 s.

my $why = SkyfieldOracle::usable();
plan skip_all => $why if $why;

my $file = 't/usno-oneday.tsv';
open my $fh, '<', $file or BAIL_OUT("$file: $!");
my (@rows, @jobs);
while (<$fh>) {
    next if /^#/;
    chomp;
    my ($place, $date, $lat, $lon, $zone) = split /\t/;
    next unless defined $zone;
    my ($y, $m, $d) = split /-/, $date;
    next if $y < 1900 || $y > 2049;
    my $day = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone)->on(year => $y, month => $m, day => $d);
    push @rows, [$place, $date, $lat, $day];
    push @jobs, { kind => 'events', body => 'sun', lat => $lat + 0, lon => $lon + 0, start => $day->start->epoch, end => $day->end->epoch };
}
close $fh;

my $answers = SkyfieldOracle::ask(\@jobs);
my %ours_of = (rise => 'sunrises', set => 'sunsets', transit => 'solar_noons', dawn => 'dawns', dusk => 'dusks');
my ($n, $worst, $worst_name, %by_band) = (0, 0, '');
for my $i (0 .. $#rows) {
    my ($place, $date, $lat, $day) = @{$rows[$i]};
    my %theirs;
    push @{$theirs{$_->[0]}}, $_->[1] for @{$answers->[$i]};
    for my $kind (sort keys %ours_of) {
        my $method = $ours_of{$kind};
        my @ours = map { $_->epoch } $day->$method;
        my @sky = @{$theirs{$kind} || []};
        # Within a degree of a pole Skyfield's search, which brackets each event
        # between transits, misses a crossing the declination makes alone (it
        # finds no sunset at 89.99 degrees in all of 20 to 30 September 2026,
        # where USNO has one on the 25th): its counts are not an oracle there.
        if (abs($lat) > 89 && @ours != @sky) {
            note("$place $date: $kind, Skyfield has " . scalar(@sky) . ", this dist " . scalar(@ours) . ": not compared within a degree of a pole");
            next;
        }
        is(scalar @ours, scalar @sky, "$place $date: " . scalar(@sky) . " $kind");
        my $mark = abs($lat) > 89 ? 1800 : abs($lat) > 60 ? 120 : 30;
        for my $j (0 .. $#sky) {
            last if $j > $#ours;
            my $diff = abs($ours[$j] - $sky[$j]);
            ($worst, $worst_name) = ($diff, "$place $date $kind") if $diff > $worst && $mark == 30;
            $by_band{$mark} = $diff if !defined $by_band{$mark} || $diff > $by_band{$mark};
            cmp_ok($diff, '<=', $mark, sprintf '%s %s: %s within %d s of Skyfield (%.1f s)', $place, $date, $kind, $mark, $diff);
            $n++;
        }
    }
}
note(sprintf "%d sun events; the worst below 60 degrees %.1f s (%s); worst by band: %s", $n, $worst, $worst_name,
     join ', ', map { sprintf '%d s band %.1f s', $_, $by_band{$_} } sort { $a <=> $b } keys %by_band);

# the seasons, 1900 to 2049. The mark, 51 s, is the error the book states for
# 1951 to 2050; against DE421 chapter 27 reaches 66 s in 1956 and 75 s in 1900
# (the tables match the port's, and Delta T agrees within 0.7 s in every year
# that misses). The mark is missed, not moved: the checks are TODO.
{
    local $TODO = 'chapter 27 exceeds its stated 51 s against DE421 (66 s in 1956)';
    my @years = map { 1900 + 7 * $_ } 0 .. 21;
    my $s = SkyfieldOracle::ask([map { { kind => 'seasons', year => $_ } } @years]);
    my $worst_s = 0;
    for my $i (0 .. $#years) {
        my @ours = Time::Keeper::Sun->seasons(year => $years[$i]);
        is(scalar @{$s->[$i]}, 4, "$years[$i]: four seasons at Skyfield");
        for my $k (0 .. 3) {
            my $diff = abs($ours[$k]->epoch - $s->[$i][$k][1]);
            $worst_s = $diff if $diff > $worst_s;
            cmp_ok($diff, '<=', 51, sprintf '%d season %d within 51 s of Skyfield (%.1f s)', $years[$i], $k, $diff);
        }
    }
    note(sprintf 'seasons: worst %.1f s', $worst_s);
}

# the moon's phases in 1950, 2000 and 2026
{
    my @spans = map { [Time::Keeper->new(year => $_, month => 1, day => 1, zone => 'UTC')->epoch,
                       Time::Keeper->new(year => $_ + 1, month => 1, day => 1, zone => 'UTC')->epoch - 1] } 1950, 2000, 2026;
    my $p = SkyfieldOracle::ask([map { { kind => 'phases', from => $_->[0], to => $_->[1] } } @spans]);
    my @kinds = qw(new first_quarter full last_quarter);
    my $worst_p = 0;
    for my $i (0 .. $#spans) {
        my @ours = Time::Keeper::Moon->phases(from => $spans[$i][0], to => $spans[$i][1]);
        is(scalar @ours, scalar @{$p->[$i]}, 'as many phases as Skyfield in the year');
        for my $j (0 .. $#ours) {
            my ($k, $e) = @{$p->[$i][$j] || [-1, 0]};
            is($ours[$j][0], $kinds[$k] // '', "phase $j is a $ours[$j][0]");
            my $diff = abs($ours[$j][1]->epoch - $e);
            $worst_p = $diff if $diff > $worst_p;
            cmp_ok($diff, '<=', 30, sprintf '%s %s within 30 s of Skyfield (%.1f s)', $ours[$j][0], $ours[$j][1], $diff);
        }
    }
    note(sprintf 'phases: worst %.1f s', $worst_p);
}

done_testing;
