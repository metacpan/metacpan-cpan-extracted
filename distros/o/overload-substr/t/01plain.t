#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::NoWarnings;

BEGIN {
   require overload::substr;
   # no import
}

my $s;

$s = substr( "Hello, world", 0, 5 );
is( $s, "Hello", 'substr extraction on constant' );

my $var = "Hello, world";

$s = substr( $var, 0, 5 );
is( $s, "Hello", 'substr extraction on variable' );

substr( $var, 0, 5, "Goodbye" );
is( $var,
    "Goodbye, world",
    'substr manipulation by replacement' );

substr( $var, 9, 0 ) = "cruel ";
is( $var,
    "Goodbye, cruel world",
    'substr manipulation by lvalue' );

Test::NoWarnings::had_no_warnings;
done_testing;
