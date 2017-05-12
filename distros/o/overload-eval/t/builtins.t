#!perl
use strict;
use warnings;
use Test::More;
our $TESTS;
plan( tests => $TESTS );

BEGIN { $TESTS += 4 }
is( `$^X -Mblib -Moverload::eval=-p -e "eval 1;eval 2"`,     '1',  '-p' );
is( `$^X -Mblib -Moverload::eval=-print -e "eval 1;eval 2"`, '1',  '-print' );
is( `$^X -Mblib -Moverload::eval=-pe -e "eval 1;eval 2"`,    '12', '-pe' );
is( `$^X -Mblib -Moverload::eval=-print-eval -e "eval 1;eval 2"`,
    '12', '-print-eval' );
