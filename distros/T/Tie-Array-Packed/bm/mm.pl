#!/usr/bin/perl

use Memchmark 'cmpthese';

use Tie::Array::PackedC DoubleNative => 'd';

use Tie::Array::Packed;

my $n = $ARGV[0] || 100_000;
$|=1;
sub test {
    my $a = shift;
    # $#$a = $n - 1;
    my $i;
    for ($i=0; $i< $n; $i++) {
        $a->[$i] = $i + .1;
        my $b = 'foo' . $a->[$i]; # convert to string
    }
    for ($i=0; $i< $n; $i++) {
        $a->[$i] += 0.2
    }
}

cmpthese(tapc => sub {
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
         } );
