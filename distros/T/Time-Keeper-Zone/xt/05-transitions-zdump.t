#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# transitions, next_transition and previous_transition against zdump for
# every zone from the year -1000 to 2500, through the public methods: each
# change's instant, offset before and after, abbreviation and DST flag;
# and each change's next is the one after it, its previous the one before.
# transitions takes at most 1,000 years, so the span is asked in pieces.
#
#   TKZ_ZIC=/path/zic TKZ_ZDUMP=/path/zdump TKZ_TZDATA=/path/tzdata-2026e.tar.gz
#
# Zones are named to zdump by absolute path: see xt/03-zdump-oracle.t.

my %env = map { $_ => $ENV{$_} } qw(TKZ_ZIC TKZ_ZDUMP TKZ_TZDATA);
for (sort keys %env) {
    plan skip_all => "$_ is not set" unless $env{$_} && -e $env{$_};
}

use Time::Keeper::Zone;

my $Z = 'Time::Keeper::Zone';
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
my @cuts = map { days($_, 1, 1) * 86400 } -1000, 0, 1000, 2000, 2500;

my ($zones, $changes, @bad, @chain) = (0, 0);
for my $name ($Z->names) {
    my @rows;
    for my $i (0 .. $#cuts - 1) {
        push @rows, $Z->transitions($name, $cuts[$i], $cuts[$i + 1] - 1);
    }
    my @mine = map { join ' ', @$_ } @rows;

    my @out = `$env{TKZ_ZDUMP} -v -c $lo_y,$hi_y $bin/$name`;
    my (@theirs, $before, $before_off);
    for (@out) {
        my ($mn, $d, $h, $mi, $s, $y, $abbr, $isdst, $off) =
            /^\S+\s+\w{3} (\w{3})\s+(\d+) (\d\d):(\d\d):(\d\d) (-?\d+) UT = .* (\S+) isdst=(\d) gmtoff=(-?\d+)$/
            or next;
        my $at = days($y, $mon{$mn}, $d) * 86400 + $h * 3600 + $mi * 60 + $s;
        push @theirs, "$at $before_off $off $abbr $isdst" if defined $before && $at == $before + 1;
        ($before, $before_off) = ($at, $off);
    }
    $zones++;
    $changes += @mine;
    if ("@mine" ne "@theirs") {
        push @bad, $name;
        if (@bad <= 3) {
            my $i = 0;
            $i++ while $i < @mine && $i < @theirs && $mine[$i] eq $theirs[$i];
            diag("$name: first difference at change $i of " . scalar(@mine) . ": mine '"
                 . ($mine[$i] // 'none') . "', zdump '" . ($theirs[$i] // 'none') . "'");
        }
    }
    for my $i (0 .. $#rows) {
        my $at = $rows[$i][0];
        my $next = $Z->next_transition($name, $i ? $rows[$i - 1][0] : $at - 1);
        my $prev = $Z->previous_transition($name, $at);
        my $want_prev = $i ? $rows[$i - 1][0] : undef;
        if (!defined $next || $next != $at
            || (defined $want_prev ? !defined $prev || $prev != $want_prev
                                   : defined $prev && $prev >= $cuts[0])) {
            push @chain, "$name at $at: next " . ($next // 'undef') . ', previous ' . ($prev // 'undef');
            last;
        }
    }
}

is(scalar @bad, 0, "transitions of all $zones zones agree with zdump from $lo_y to $hi_y, $changes changes")
    or diag("differ: @bad[0 .. ($#bad < 9 ? $#bad : 9)]");
is(scalar @chain, 0, 'next_transition and previous_transition step from each change to its neighbours')
    or diag(join "\n", @chain[0 .. ($#chain < 9 ? $#chain : 9)]);

done_testing;
