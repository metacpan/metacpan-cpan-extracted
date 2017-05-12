#! /usr/bin/perl
use Test::More;
use Perlude;
use strict;
use warnings;

for
( [ "perlude respect multivalued returns",
     [ fold take 3, sub { 1, 2 } ]
     => [qw( 1 2 1 )] ] 
, [ "apply respect multivalued returns",
    [ fold take 3, apply { $_, $_ } sub { 8, 9 } ]
    => [qw( 8 8 8 )] ] 
) {
    my ( $desc, $got, $expected ) = @$_;
    is_deeply $got, $expected, $desc;
}

done_testing;
