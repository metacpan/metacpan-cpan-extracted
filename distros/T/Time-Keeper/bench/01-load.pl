#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::HiRes qw(time);

# Load time in a fresh process: the median of many runs of perl -MModule -e1,
# less the median of perl -e1 with the same @INC.
my $N = $ENV{TK_BENCH_LOADS} // 41;
sub median_run {
    my ($code, @args) = @_;
    my @t;
    for (1 .. $N) {
        my $t0 = time;
        system($^X, '-Mblib', @args, '-e', $code) == 0 or die "perl @args failed\n";
        push @t, time - $t0;
    }
    @t = sort { $a <=> $b } @t;
    return $t[$#t / 2];
}
my $base = median_run('1');
my %ms = map { $_ => (median_run('1', "-M$_") - $base) * 1000 } qw(Time::Keeper Time::Piece DateTime);
my $named = (median_run('Time::Keeper->now(zone => q{Asia/Tokyo})', '-MTime::Keeper') - $base) * 1000;
printf "info load: Time::Keeper %.1f ms, with its first named zone %.1f ms; Time::Piece %.1f ms; DateTime %.1f ms (over perl -e1, median of %d)\n",
    $ms{'Time::Keeper'}, $named, $ms{'Time::Piece'}, $ms{DateTime}, $N;
$_ = sprintf('%.1f', $_) for values %ms;
mark_less('use, fresh process', $ms{'Time::Keeper'}, $ms{'Time::Piece'}, 1, 'Time::Piece', 'ms');
mark_less('use, fresh process', $ms{'Time::Keeper'}, $ms{DateTime}, 10, 'DateTime', 'ms');
done();
