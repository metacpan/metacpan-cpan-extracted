#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# The engine against zdump for every zone from the year -1000 to 2500:
# every change of offset, DST flag or abbreviation, at the second it
# happens. Past each zone's last transition the engine works the changes
# out from the zone's TZ string, and so does zdump, independently.
#
#   TKZ_ZIC=/path/zic TKZ_ZDUMP=/path/zdump TKZ_TZDATA=/path/tzdata-2026e.tar.gz
#
# Zones are named to zdump by absolute path: see xt/03-zdump-oracle.t.

my %env = map { $_ => $ENV{$_} } qw(TKZ_ZIC TKZ_ZDUMP TKZ_TZDATA);
for (sort keys %env) {
    plan skip_all => "$_ is not set" unless $env{$_} && -e $env{$_};
}

use Time::Keeper::Zone;

my $src = tempdir(CLEANUP => 1);
my $bin = tempdir(CLEANUP => 1);
system('tar', '-xzf', $env{TKZ_TZDATA}, '-C', $src) == 0 or die "tar failed\n";
system($env{TKZ_ZIC}, '-b', 'fat', '-d', $bin,
       map { "$src/$_" } qw(africa antarctica asia australasia europe northamerica
                            southamerica etcetera backward)) == 0 or die "zic failed\n";

my %mon = (Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6,
           Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12);
sub days {
    my ($y, $m, $d) = @_;
    $y -= $m <= 2;
    my $era = int(($y >= 0 ? $y : $y - 399) / 400);
    my $yoe = $y - $era * 400;
    my $doy = int((153 * ($m > 2 ? $m - 3 : $m + 9) + 2) / 5) + $d - 1;
    return $era * 146097 + $yoe * 365 + int($yoe / 4) - int($yoe / 100) + $doy - 719468;
}

my ($lo_y, $hi_y) = (-1000, 2500);
my ($lo, $hi) = (days($lo_y, 1, 1) * 86400, days($hi_y, 1, 1) * 86400 - 1);

my ($zones, $changes, @bad) = (0, 0);
for my $name (Time::Keeper::Zone->names) {
    my @mine = map { join ' ', @$_ } Time::Keeper::Zone::_changes($name, $lo, $hi);
    my @out = `$env{TKZ_ZDUMP} -v -c $lo_y,$hi_y $bin/$name`;
    my (@theirs, $before);
    for (@out) {
        my ($mn, $d, $h, $mi, $s, $y, $abbr, $isdst, $off) =
            /^\S+\s+\w{3} (\w{3})\s+(\d+) (\d\d):(\d\d):(\d\d) (-?\d+) UT = .* (\S+) isdst=(\d) gmtoff=(-?\d+)$/
            or next;
        my $at = days($y, $mon{$mn}, $d) * 86400 + $h * 3600 + $mi * 60 + $s;
        push @theirs, "$at $off $isdst $abbr" if defined $before && $at == $before + 1;
        $before = $at;
    }
    $zones++;
    $changes += @mine;
    next if "@mine" eq "@theirs";
    push @bad, $name;
    if (@bad <= 3) {
        my $i = 0;
        $i++ while $i < @mine && $i < @theirs && $mine[$i] eq $theirs[$i];
        diag("$name: first difference at change $i of " . scalar(@mine) . ": mine '"
             . ($mine[$i] // 'none') . "', zdump '" . ($theirs[$i] // 'none') . "'");
    }
}

is(scalar @bad, 0, "all $zones zones agree with zdump from $lo_y to $hi_y, $changes changes")
    or diag("differ: @bad[0 .. ($#bad < 9 ? $#bad : 9)]");

done_testing;
