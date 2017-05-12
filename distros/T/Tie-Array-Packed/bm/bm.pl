#!/usr/bin/perl

use Benchmark 'cmpthese';

use Tie::Array::PackedC DoubleNative => 'd';

use Tie::Array::Packed;

my $n = 20000;

sub test {

    my $a = shift;

    $#$a = $n + 1;

    for (1..$n) {
        $a->[$_] = $n;
    }

    for (1..$n) {
        $a->[$_] += .2
    }

    # @$a = reverse @$a;

}

cmpthese(-1, { tapc => sub {
                   my @a;
                   tie @a, Tie::Array::PackedC::DoubleNative;
                   test \@a },
               tap => sub {
                   my @a;
                   tie @a, Tie::Array::Packed::DoubleNative;
                   test \@a
               },
               bi => sub {
                   my @a;
                   test \@a
               } } );
