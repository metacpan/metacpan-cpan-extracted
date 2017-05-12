#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner tests => 2;

sub create_chain {
 my ($l, $n) = @_;

 $n = 1  unless defined $n;
 $l = 45 unless defined $l;

 return \(\$n) if $l <= 0;

 [
  [ 0, \(\$n) ],
  1,
  { a => create_chain($l - 1, $n + 1) },
 ]
}

my $c1 = create_chain;
my $c2 = create_chain;

is_deeply $c1, $c2, 'a deep chain structure';

sub create_tree {
 my ($l, $n) = @_;

 $n = 1  unless defined $n;
 $l = 10 unless defined $l;

 return \(\$n) if $l <= 0;

 [
  { a => create_tree($l - 1, 2 * $n) },
  1,
  { b => create_tree($l - 1, 2 * $n + 1) },
 ]
}

my $t1 = create_tree;
my $t2 = create_tree;

is_deeply $t1, $t2, 'a deep tree structure';
