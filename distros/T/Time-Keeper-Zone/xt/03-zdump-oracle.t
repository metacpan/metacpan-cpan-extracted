#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Every zone's compiled transitions against zdump, the reference reader
# from the same tzcode release. Author only: it needs that release's zic
# and zdump, and the tzdata tarball, named by environment variables.
#
#   TKZ_ZIC=/path/zic TKZ_ZDUMP=/path/zdump TKZ_TZDATA=/path/tzdata-2026e.tar.gz
#
# zdump reads files zic writes here with "-b fat", which spells out every
# transition, so it does not see the "slim" files tools/tzcompile read.
# Each zone is named to zdump by its file's absolute path. A bare name is
# looked up in the zoneinfo directory zdump was BUILT with: the build ignores
# TZDIR, and on macOS that directory holds the system's own tzdata (2026d,
# rearguard), which once passed 338 of 344 zones here while testing nothing.
#
# The comparison stops at each zone's last compiled transition: what comes
# after is the TZ string's to answer, and that is Phase 04's test.

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

sub days_from_civil {
    my ($y, $m, $d) = @_;
    $y -= $m <= 2;
    my $era = int(($y >= 0 ? $y : $y - 399) / 400);
    my $yoe = $y - $era * 400;
    my $doy = int((153 * ($m > 2 ? $m - 3 : $m + 9) + 2) / 5) + $d - 1;
    my $doe = $yoe * 365 + int($yoe / 4) - int($yoe / 100) + $doy;
    return $era * 146097 + $doe - 719468;
}

my @rows = Time::Keeper::Zone::_lookup_table();
my @zones;
while (my ($name, undef, $link) = splice @rows, 0, 3) { push @zones, $name unless $link }

my ($checked, $changes, @bad) = (0, 0);
for my $name (@zones) {
    my $z = Time::Keeper::Zone::_zone_dump($name);
    my @mine;
    my $prev = join ' ', @{ $z->{initial} };
    for my $t (@{ $z->{transitions} }) {
        my ($at, @type) = @$t;
        my $now = join ' ', @type;
        push @mine, "$at $now" if $now ne $prev;
        $prev = $now;
    }
    my $last = @{ $z->{transitions} } ? $z->{transitions}[-1][0] : 0;
    my $hi = 1970 + int($last / 31_556_952) + 2;

    my @out = `$env{TKZ_ZDUMP} -v -c -1000,$hi $bin/$name`;
    my (@theirs, $before);
    for (@out) {
        my ($mn, $d, $h, $mi, $s, $y, $abbr, $isdst, $off) =
            /^\S+\s+\w{3} (\w{3})\s+(\d+) (\d\d):(\d\d):(\d\d) (-?\d+) UT = .* (\S+) isdst=(\d) gmtoff=(-?\d+)$/
            or next;
        my $at = days_from_civil($y, $mon{$mn}, $d) * 86400 + $h * 3600 + $mi * 60 + $s;
        push @theirs, "$at $off $isdst $abbr"
            if defined $before && $at == $before + 1 && $at <= $last;
        $before = $at;
    }
    $checked++;
    $changes += @mine;
    push @bad, $name unless "@mine" eq "@theirs";
    if ("@mine" ne "@theirs" && @bad <= 3) {
        my $i = 0;
        $i++ while $i < @mine && $i < @theirs && $mine[$i] eq $theirs[$i];
        diag("$name: first difference at change $i: mine '" . ($mine[$i] // 'none')
             . "', zdump '" . ($theirs[$i] // 'none') . "'");
    }
}

is(scalar @bad, 0, "all $checked zones agree with zdump on $changes changes of offset, daylight time or abbreviation")
    or diag("differ: @bad[0 .. ($#bad < 9 ? $#bad : 9)]");

done_testing;
