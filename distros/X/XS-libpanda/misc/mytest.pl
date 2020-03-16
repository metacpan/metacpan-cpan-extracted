#!/usr/bin/env perl
use 5.012;
use XS::libpanda;
use Benchmark qw/timethis timethese/;

timethese(-1, {
    panda_error_code => sub { XS::libpanda::bench_error_code(1000) },
    std_error_code   => sub { XS::libpanda::bench_std_error_code(1000) },
});
