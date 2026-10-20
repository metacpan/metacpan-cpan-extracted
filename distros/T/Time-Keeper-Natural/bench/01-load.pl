#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::HiRes ();

# use Time::Keeper::Natural, over use Time::Keeper, in fresh processes; the median.
my $n = $ENV{TKN_BENCH_LOADS} // 41;
sub load {
    my ($module) = @_;
    my @t;
    for (1 .. $n) {
        my $t0 = [Time::HiRes::gettimeofday()];
        system($^X, '-Mblib', "-M$module", '-e', '1') == 0 or die "$module did not load\n";
        push @t, Time::HiRes::tv_interval($t0);
    }
    @t = sort { $a <=> $b } @t;
    return $t[ $#t / 2 ];
}
my ($base, $mine) = (load('Time::Keeper'), load('Time::Keeper::Natural'));
mark_most('use, over use Time::Keeper', sprintf('%.1f', 1000 * ($mine - $base)), 2, 'ms');
done();
