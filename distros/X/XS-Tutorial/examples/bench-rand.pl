#!/usr/bin/perl
use Benchmark 'cmpthese';
use XS::Tutorial::One;

XS::Tutorial::One::srand(777);

cmpthese(-5, {
  bi_rand => sub { rand() },
  tu_rand => sub { XS::Tutorial::One::rand() },
});
