#!perl

package abc;

our $scalar;
our @array;
our %hash;
sub code;

package abc::def;

our $scalar;
our @array;
our %hash;
sub code;

package main;

use strict;
use warnings FATAL => 'all';
use Test::Most qw(!code);
use Tie::Symbol;

plan tests => 6;

tie( my %ST_abc, 'Tie::Symbol', 'abc' );
tie( my %ST_def, 'Tie::Symbol', 'abc::def' );

my @abc_symbols = keys %ST_abc;
my @def_symbols = keys %ST_def;

is_deeply \@abc_symbols => [ sort qw[ $scalar %hash &code def @array ] ],
  'symbols in abc';
is_deeply \@def_symbols => [ sort qw[ $scalar %hash &code @array ] ],
  'symbols in abc::def';

is exists( $ST_abc{'$scalar'} ) => 1, '$scalar exists';
is exists( $ST_abc{'@array'} )  => 1, '@array exists';
is exists( $ST_abc{'%hash'} )   => 1, '%hash exists';
is exists( $ST_abc{'&code'} )   => 1, '&code exists';

done_testing;
