#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Mojo::Util::Benchmark;

my $benchmark = Mojo::Util::Benchmark->new->milliseconds;
$benchmark->start('fetch users');

is($benchmark->timers->{ 'fetch users' }->{ digits }, 4);
isnt($benchmark->timers->{ 'fetch users' }->{ start }, undef);
is($benchmark->timers->{ 'fetch users' }->{ stop }, undef);

$benchmark->stop('fetch users');

isnt($benchmark->timers->{ 'fetch users' }->{ stop }, undef);

done_testing();
