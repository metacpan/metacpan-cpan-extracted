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

plan tests => 47;

tie( my %ST, 'Tie::Symbol' );

isa_ok $ST{'abc'}          => 'Tie::Symbol';
isa_ok $ST{'def'}          => 'Tie::Symbol';
isa_ok $ST{'abc::def'}     => 'Tie::Symbol';
isa_ok $ST{'abc'}->{'def'} => 'Tie::Symbol';

isa_ok $ST{'abc'}->{'$scalar'} => 'SCALAR';
isa_ok $ST{'abc'}->{'@array'}  => 'ARRAY';
isa_ok $ST{'abc'}->{'%hash'}   => 'HASH';
isa_ok $ST{'abc'}->{'&code'}   => 'CODE';

isa_ok $ST{'$abc::scalar'} => 'SCALAR';
isa_ok $ST{'@abc::array'}  => 'ARRAY';
isa_ok $ST{'%abc::hash'}   => 'HASH';
isa_ok $ST{'&abc::code'}   => 'CODE';

isa_ok $ST{'abc'}->{'def'}->{'$scalar'} => 'SCALAR';
isa_ok $ST{'abc'}->{'def'}->{'@array'}  => 'ARRAY';
isa_ok $ST{'abc'}->{'def'}->{'%hash'}   => 'HASH';
isa_ok $ST{'abc'}->{'def'}->{'&code'}   => 'CODE';

isa_ok $ST{'$abc::def::scalar'} => 'SCALAR';
isa_ok $ST{'@abc::def::array'}  => 'ARRAY';
isa_ok $ST{'%abc::def::hash'}   => 'HASH';
isa_ok $ST{'&abc::def::code'}   => 'CODE';

isa_ok $ST{'abc'}->{'$def::scalar'} => 'SCALAR';
isa_ok $ST{'abc'}->{'@def::array'}  => 'ARRAY';
isa_ok $ST{'abc'}->{'%def::hash'}   => 'HASH';
isa_ok $ST{'abc'}->{'&def::code'}   => 'CODE';

tie( my %ST_abc, 'Tie::Symbol', 'abc' );

isa_ok $ST_abc{'$scalar'} => 'SCALAR';
isa_ok $ST_abc{'@array'}  => 'ARRAY';
isa_ok $ST_abc{'%hash'}   => 'HASH';
isa_ok $ST_abc{'&code'}   => 'CODE';

isa_ok $ST_abc{'$def::scalar'} => 'SCALAR';
isa_ok $ST_abc{'@def::array'}  => 'ARRAY';
isa_ok $ST_abc{'%def::hash'}   => 'HASH';
isa_ok $ST_abc{'&def::code'}   => 'CODE';

my $def1 = $ST_abc{'def'};
my $def2 = $ST{'abc::def'};
my $def3 = $ST{'abc'}->{'def'};

is_deeply $def1, $def2, '$ST_abc{def} == $ST{abc::def}';
is_deeply $def2, $def3, '$ST{abc::def} == $ST{abc}->{def}';
is_deeply $def3, $def1, '$ST{abc}->{def} == $ST_abc{def}';

is $def1->namespace => 'abc::def',       'def1->namespace';
is $def2->namespace => 'main::abc::def', 'def2->namespace';
is $def3->namespace => 'main::abc::def', 'def3->namespace';

my $abc = $def1->parent;
isa_ok $abc        => 'Tie::Symbol', 'def1->parent';
is $abc->namespace => 'abc',         'parent of abc::def is abc';
is $abc->parent    => undef,         'abc has not parent';

is $def2->parent->namespace => 'main::abc',
  '(def2) parent of main::abc::def is main::abc';
is $def2->parent->parent->namespace => 'main',
  '(def2) parent of main::abc is main';
is $def2->parent->parent->parent => undef, '(def2) main has not parent';

is $def3->parent->namespace => 'main::abc',
  '(def3) parent of main::abc::def is main::abc';
is $def3->parent->parent->namespace => 'main',
  '(def3) parent of main::abc is main';
is $def3->parent->parent->parent => undef, '(def3) main has not parent';

done_testing;
