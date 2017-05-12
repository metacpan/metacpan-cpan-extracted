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

plan tests => 15;

my $ST_abc = Tie::Symbol->new('abc');
my $ST_def = Tie::Symbol->new('abc::def');

my @abc_symbols = keys %$ST_abc;
my @def_symbols = keys %$ST_def;

is_deeply \@abc_symbols => [qw[ $scalar %hash &code @array def ]],
  'symbols in abc';
is_deeply \@def_symbols => [qw[ $scalar %hash &code @array ]],
  'symbols in abc::def';

is exists( $ST_abc->{'$scalar'} ) => 1, '$scalar exists';
is exists( $ST_abc->{'@array'} )  => 1, '@array exists';
is exists( $ST_abc->{'%hash'} )   => 1, '%hash exists';
is exists( $ST_abc->{'&code'} )   => 1, '&code exists';

is_deeply [ $ST_abc->scalars ] => [qw[ $scalar ]], 'scalars';
is_deeply [ $ST_abc->hashes ]  => [qw[ %hash ]],   'hashed';
is_deeply [ $ST_abc->arrays ]  => [qw[ @array ]],  'array';
is_deeply [ $ST_abc->subs ]    => [qw[ &code ]],   'subroutines';
is_deeply [ $ST_abc->classes ] => [qw[ def ]],     'subclasses';

is_deeply $ST_abc->tree => { def => {} },
  'tree';
is_deeply $ST_abc => {
    '$scalar' => \$abc::scalar,
    '@array'  => \@abc::array,
    '%hash'   => \%abc::hash,
    '&code'   => \&abc::code,
    def       => {
        '$scalar' => \$abc::def::scalar,
        '@array'  => \@abc::def::array,
        '%hash'   => \%abc::def::hash,
        '&code'   => \&abc::def::code,
    }
  },
  'dump';

is_deeply $ST_abc->{def} => $ST_def;

my $ST_xyz = Tie::Symbol->new('xyz');
is_deeply $ST_xyz->tree => {};

done_testing;
