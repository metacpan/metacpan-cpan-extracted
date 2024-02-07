use strict;
use warnings;

use Data::Dumper;
use Mojo::Util::Benchmark qw(benchmark);

# my $benchmark = benchmark(output => 1)->nanoseconds;
#
# $benchmark->start;
# sleep 1;
# $benchmark->stop;

my $a = 1;

my $sum = sub {
    $a += 1;
};

my $prod = sub {
    $a *= 2;
};

my $avg = benchmark(output => 0)->average($prod, 150);

print "Avg: $avg\n";

$avg = benchmark(output => 0)->average($sum, 150);

print "Avg: $avg\n";

my $series = benchmark(output => 0)->series($prod, 10);

warn Dumper $series;
