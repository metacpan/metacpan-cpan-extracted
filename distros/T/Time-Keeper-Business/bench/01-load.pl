#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::HiRes qw(time);

# Load time in a fresh process: the median of many runs, the module's over
# Time::Keeper's own.
my $N = $ENV{TK_BENCH_LOADS} // 41;
sub median_run {
    my (@args) = @_;
    my @t;
    for (1 .. $N) {
        my $t0 = time;
        system($^X, '-Mblib', @args, '-e', '1') == 0 or die "perl @args failed\n";
        push @t, time - $t0;
    }
    @t = sort { $a <=> $b } @t;
    return $t[$#t / 2];
}
my $core = median_run('-MTime::Keeper');
my $mine = median_run('-MTime::Keeper::Business');
my $extra = sprintf '%.2f', ($mine - $core) * 1000;
printf "info load: Time::Keeper %.1f ms, Time::Keeper::Business %.1f ms (median of %d)\n", $core * 1000, $mine * 1000, $N;
mark_less('use, beyond Time::Keeper', $extra, 1, 1, 'the mark', 'ms');
done();
