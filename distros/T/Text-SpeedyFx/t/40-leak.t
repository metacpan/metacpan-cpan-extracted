#!perl
use strict;
use utf8;
use warnings;

use Test::More;

eval q(use Devel::Leak);
plan skip_all => q(Devel::Leak required)
    if $@;

sub test_leak (&$;$) {
    my ($code, $descr, $maxleak) = (@_, 0);
    my $n1 = Devel::Leak::NoteSV(my $handle);
    $code->() for 1 .. 100;
    my $n2 = Devel::Leak::CheckSV($handle);
    cmp_ok($n1 + $maxleak, '>=', $n2, $descr);
}

use Text::SpeedyFx;

my $n = 20;

# warm up
Text::SpeedyFx->new(($_) x 2)
    for 8 .. 18;
Text::SpeedyFx->new->hash(q(Hello, World!));

for my $bits (reverse 1 .. $n) {
    test_leak {
        Text::SpeedyFx
            ->new(($bits) x 2)
            ->hash(qq(
                Lorem ipsum dolor sit amet,
                consectetur adipisicing elit,
                sed do eiusmod tempor incididunt
                ut labore et dolore magna aliqua.
            ));
    } qq($bits bits)
}

done_testing($n);
