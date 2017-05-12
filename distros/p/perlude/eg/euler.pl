#! /usr/bin/perl
use Eirotic;

sub sum ($xs) {
    my $sum = 0;
    now {state $sum=0; $sum+=$_ } $xs
}

say "euler 1: ",
    sum filter {
        not
        ( ($_ % 3)
        ||($_ % 5))
    } range 1, 1000;

sub fibo (@seed) {
    sub {
        push @seed, $seed[0] + $seed[1];
        shift @seed;
    }
} 

say "euler 2: ",
    sum filter { not ($_ % 2) }
    takeWhile { $_ < 4_000_000 }
    fibo 1, 1;

sub is_prime ($x=$_) {
    map { return 0 unless $x % $_ } 2..($x-1);
    1
}

say now {$_}
    filter {is_prime}
    range 1, 600_851_475_143;

