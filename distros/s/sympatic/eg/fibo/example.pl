package Fibo;
use Sympatic -oo;
use Types::Standard qw< Tuple Int >;
use Types::Fibo;

has seed =>
    ( is  => 'rw'
    , isa => Types::Fibo::Seed
    , default => sub {[0, 1]} );

fun sum ( $x, $y ) { $x + $y }

method next () {
    my $s = $self->seed;
    push @$s, sum @$s;
    shift @$s;
}

package main;
use Sympatic;

my $f = Fibo->new;

say $f->next;
say $f->next;
say $f->next;
say $f->next;

