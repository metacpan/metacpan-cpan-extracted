#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Capture::Tiny qw(capture);
use Test::More;

use Mojo::Util::Benchmark;

my $benchmark = Mojo::Util::Benchmark->new(output => 1);

$benchmark->start('first function');
my ($stdout1) = capture { $benchmark->stop('first function') };

like($stdout1, qr/first function: \d+(\.\d{12})?$/);

$benchmark->microseconds->start('second function');
my ($stdout2) = capture { $benchmark->stop('second function') };

like($stdout2, qr/second function: \d+(\.\d{8})?$/);

done_testing();
