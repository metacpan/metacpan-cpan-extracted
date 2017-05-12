#! /usr/bin/perl
use strict;
use warnings;
use 5.10.0;
use Test::More skip_all => 'range not implemented';
use Perlude qw/ fold range /;

sub fold_for {
    my ( $args, $expected, $description ) = @_;
    is_deeply( [ fold range @$args ], $expected, $description )
}

fold_for [1,5]   , [1..5]           , "range works with no step" ; 
fold_for [1,1]   , [1]              , "range with 1 element"     ;
fold_for [0,9,2] , [0, 2, 4, 6, 8]  , "range with step 2"        ;

# plan skip_all => "i don't know what to do with inverted min,max";
# fold_for [5,1]   , []             , "inverted range is empty"  ;
