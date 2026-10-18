#!perl
# round with increments and modes against an integer model. Author only.
# In UTC between 2017 and 2026 there are no leap seconds and no changes of
# the clocks, so a clock unit's bucket is plain arithmetic on the
# nanoseconds since midnight: the model does that in Perl integers (a day
# is 8.64e13 ns, well inside 2**53) and the value must agree to the
# nanosecond in every mode and increment.
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
my $N = $ENV{TK_ORACLE_N} || 20_000;
srand($ENV{TK_SEED} || 20261017);

my %unit_ns = (hour => 3_600_000_000_000, minute => 60_000_000_000, second => 1_000_000_000,
               millisecond => 1_000_000, microsecond => 1_000, nanosecond => 1);
my %incs = (hour => [1, 2, 3, 4, 6, 8, 12], minute => [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30],
            second => [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30],
            millisecond => [1, 2, 4, 5, 8, 10, 20, 25, 40, 50, 100, 125, 200, 250, 500]);
$incs{microsecond} = $incs{nanosecond} = $incs{millisecond};
my @modes = qw(floor ceil half_floor half_ceil half_even);
my ($lo_epoch, $hi_epoch) = (1_483_228_800, 1_798_761_599);   # 2017-01-01 to 2026-12-31
my $bad = 0;

for my $i (1 .. $N) {
    my $epoch = $lo_epoch + int(rand($hi_epoch - $lo_epoch));
    my $nsec  = rand() < 0.1 ? 0 : int(rand(1e9));
    my $unit  = (sort keys %unit_ns)[int(rand(6))];
    my $inc   = $incs{$unit}[int(rand(@{ $incs{$unit} }))];
    my $mode  = $modes[int(rand(@modes))];
    my $sod   = $epoch % 86400;
    my $T     = $sod * 1_000_000_000 + $nsec;
    my $L     = $inc * $unit_ns{$unit};
    my $lo    = $T - $T % $L;
    my $rem   = $T - $lo;
    my $index = $lo / $L;
    my $up = $mode eq 'floor'      ? 0
           : $mode eq 'ceil'       ? $rem > 0
           : $mode eq 'half_floor' ? 2 * $rem > $L
           : $mode eq 'half_ceil'  ? 2 * $rem >= $L && $rem > 0
           :                         2 * $rem > $L || (2 * $rem == $L && $index % 2);
    my $R = $lo + ($up ? $L : 0);
    my $want_epoch = $epoch - $sod + int($R / 1_000_000_000);
    my $want_nsec  = $R % 1_000_000_000;
    my $t   = $K->from_epoch($epoch)->plus(nanoseconds => $nsec);
    my $got = $t->round(to => $unit, increment => $inc, mode => $mode);
    next if $got->epoch == $want_epoch && $got->nanosecond == $want_nsec;
    $bad++;
    diag("round $t to $inc $unit $mode: got $got, want epoch $want_epoch nsec $want_nsec");
    last if $bad > 20;
}
is($bad, 0, "$N random values agree with the integer model in every mode and increment");

done_testing;
