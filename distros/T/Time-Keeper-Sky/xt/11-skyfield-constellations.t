#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
BEGIN { require './xt/skyfield_oracle.pl' }
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Moon;

# Author test: the moon's constellation every hour of 2026 against
# Skyfield's constellation map (the same IAU boundaries, its own
# precession). The moon crosses a boundary in about an hour; at the crossing
# the two may differ by the seconds their precessions and aberration differ,
# so a difference counts only if this dist does not agree within two
# minutes either side.

my $why = SkyfieldOracle::usable();
plan skip_all => $why if $why;

my $t0 = Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC')->epoch;
my @e = map { $t0 + $_ * 3600 } 0 .. 365 * 24 - 1;
my $theirs = SkyfieldOracle::ask([{ kind => 'moon_constellations', epochs => \@e }])->[0];
my ($same, $near, @far) = (0, 0);
for my $i (0 .. $#e) {
    my $ours = Time::Keeper::Moon->position($e[$i])->{constellation};
    if ($ours eq $theirs->[$i]) { $same++; next }
    if (grep { Time::Keeper::Moon->position($e[$i] + $_)->{constellation} eq $theirs->[$i] } -120, 120) { $near++; next }
    push @far, scalar(gmtime $e[$i]) . " ours $ours, Skyfield $theirs->[$i]";
}
is(scalar @far, 0, "the moon's constellation at $same of " . scalar(@e) . " hours of 2026 as Skyfield's, $near more within two minutes of a boundary") or diag(join "\n", @far[0 .. ($#far < 9 ? $#far : 9)]);

done_testing;
