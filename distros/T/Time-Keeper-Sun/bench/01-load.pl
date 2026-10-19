#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::HiRes qw(time);

# Load time in a fresh process: the median of many runs of perl -MModule -e1,
# less the median of perl -MTime::Keeper -e1, since Time::Keeper::Sun does
# not load Time::Keeper until a method needs it, and a program that uses the
# sun has Time::Keeper anyway.
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
my $base = median_run();
my $keeper = median_run('-MTime::Keeper') - $base;
my $sun = median_run('-MTime::Keeper::Sun') - $base;
my $both = median_run('-MTime::Keeper', '-MTime::Keeper::Sun', '-MTime::Keeper::Moon') - $base;
printf "info load: Time::Keeper::Sun alone %.1f ms; Time::Keeper %.1f ms; Sun and Moon over Time::Keeper %.1f ms (median of %d)\n",
    $sun * 1000, $keeper * 1000, ($both - $keeper) * 1000, $N;
mark_less('use, over Time::Keeper, fresh process', sprintf('%.1f', ($both - $keeper) * 1000), 2, 1, 'the mark', 'ms');
done();
