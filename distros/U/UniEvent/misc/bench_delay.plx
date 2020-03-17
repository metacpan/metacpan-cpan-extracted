#!/usr/bin/env perl
use 5.012;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use UniEvent;

XS::Loader::load_tests('MyTest');
$SIG{PIPE} = 'IGNORE';

my $l = UE::Loop->default;

say "START $$";

say "delay/cancel";
my $sub = sub{};
timethis(-1, sub {
    for (1..10) {
        my $i = $l->delay($sub);
        #$l->cancel_delay($i);
    }
    $l->run_nowait;
});
timethis(-1, sub { MyTest::_bench_delay_add_rm(10); $l->run_nowait });

