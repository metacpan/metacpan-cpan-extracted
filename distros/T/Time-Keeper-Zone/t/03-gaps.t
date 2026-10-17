#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper::Zone;

# Every change of offset in 2026, in every zone, read as a gap (the clocks
# went forward) or an overlap (they went back), and the wall-clock times at
# its edges and in its middle resolved with every option.

my ($EXACT, $OVERLAP, $GAP) = (0, 1, 2);
my $y2026 = 1767225600;
my $y2027 = 1798761600;

my %n = (gaps => 0, overlaps => 0, checks => 0);
my @bad;
sub check {
    my ($ok, $what) = @_;
    $n{checks}++;
    push @bad, $what unless $ok;
}
sub resolve { [Time::Keeper::Zone::_resolve_local(@_)] }

for my $zone (Time::Keeper::Zone->names) {
    my @changes = Time::Keeper::Zone::_changes($zone, $y2026 - 1, $y2027);
    for my $c (@changes) {
        my $t = $c->[0];
        my ($before) = Time::Keeper::Zone::_offset_at($zone, $t - 1);
        my $after = $c->[1];
        next if $before == $after;
        my ($lo, $hi) = $before < $after ? ($t + $before, $t + $after) : ($t + $after, $t + $before);
        my $mid = $lo + int(($hi - $lo) / 2);
        my $tag = "$zone at $t";

        check(resolve($zone, $lo - 1, 0, 0)->[0] == $EXACT, "$tag: the second before is exact");
        if ($before < $after) {
            $n{gaps}++;
            check(resolve($zone, $lo - 1, 0, 0)->[1] == $t - 1, "$tag: the second before is the second before");
            check(resolve($zone, $hi, 0, 0)->[0] == $EXACT && resolve($zone, $hi, 0, 0)->[1] == $t,
                  "$tag: the end of the gap is the transition");
            for my $l ($lo, $mid, $hi - 1) {
                my $r = resolve($zone, $l, 0, 0);
                check($r->[0] == $GAP && !defined $r->[1], "$tag: $l is in the gap, and croak gives no instant");
                check(resolve($zone, $l, 1, 0)->[1] == $l - $before, "$tag: $l forward is read with the offset before");
                check(resolve($zone, $l, 2, 0)->[1] == $l - $after, "$tag: $l backward is read with the offset after");
                check(resolve($zone, $l, 1, 0)->[1] >= $t, "$tag: forward lands after the transition");
                check(resolve($zone, $l, 2, 0)->[1] < $t, "$tag: backward lands before it");
            }
        }
        else {
            $n{overlaps}++;
            check(resolve($zone, $hi, 0, 0)->[0] == $EXACT, "$tag: the end of the overlap is exact");
            for my $l ($lo, $mid, $hi - 1) {
                my $later = resolve($zone, $l, 0, 0);
                my $earlier = resolve($zone, $l, 0, 1);
                check($later->[0] == $OVERLAP && $earlier->[0] == $OVERLAP, "$tag: $l is in the overlap");
                check($later->[1] == $l - $after, "$tag: $l later is read with the offset after");
                check($earlier->[1] == $l - $before, "$tag: $l earlier with the offset before");
                check($later->[1] >= $t && $earlier->[1] < $t, "$tag: on either side of the transition");
            }
        }
    }
}

cmp_ok($n{gaps}, '>', 100, "$n{gaps} gaps in 2026");
cmp_ok($n{overlaps}, '>', 100, "$n{overlaps} overlaps");
is(scalar @bad, 0, "all $n{checks} checks of them pass") or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);

# Round trips: a wall-clock time read from an instant resolves back to that
# instant, or in an overlap to it or its twin.
srand(4);
my @names = Time::Keeper::Zone->names;
my ($rt, $rtbad) = (0, 0);
for (1 .. 20_000) {
    my $zone = $names[int rand @names];
    my $t = int(rand(2 * 4_000_000_000)) - 4_000_000_000;
    my ($off) = Time::Keeper::Zone::_offset_at($zone, $t);
    my ($r, $u) = Time::Keeper::Zone::_resolve_local($zone, $t + $off, 0, 0);
    my ($r2, $u2) = Time::Keeper::Zone::_resolve_local($zone, $t + $off, 0, 1);
    $rt++;
    $rtbad++ unless ($r == $EXACT && $u == $t) || ($r == $OVERLAP && ($u == $t || $u2 == $t));
}
is($rtbad, 0, "$rt random instants from 1843 to 2096 come back from their wall-clock time");

done_testing;
