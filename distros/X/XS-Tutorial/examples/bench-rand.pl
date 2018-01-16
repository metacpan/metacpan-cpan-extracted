#!/usr/bin/perl
use Benchmark 'cmpthese';
use XS::Tutorial::One;

XS::Tutorial::One::srand(777);

cmpthese(-5, {
  bi_rand => sub { rand() },
  tu_rand => sub { XS::Tutorial::One::rand() },
});

__END__

               Rate tu_rand bi_rand
tu_rand  29707150/s      --    -72%
bi_rand 105154692/s    254%      --

