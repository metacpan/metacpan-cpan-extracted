#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner tests => 7 * 10 + 4 * 7 + 10;

{
 package Test::Leaner::TestCmpNum;

 use overload '<=>' => sub {
  my ($x, $y, $r) = @_;

  $x = $x->{num};
  $y = $y->{num} if ref $y;

  ($x, $y) = ($y, $x) if $r;

  return $x <=> $y;
 };

 sub new {
  my $class = shift;

  bless { num => $_[0] }, $class
 }
}

my @num_tests = (
 [ '1.0', '==', '1.0' ],
 [ '1e0', '==', '1e0' ],
 [ '1.0', '<=', '1.0' ],
 [ '1.0', '>=', '1.0' ],
 [ '1.0', '<=', '2.0' ],
 [ '1.0', '<',  '2.0' ],
 [ '2.0', '>=', '1.0' ],
 [ '2.0', '>',  '1.0' ],
 [ '1.0', '!=', '2.0' ],
 [ '2.0', '!=', '1.0' ],
);

for my $t (@num_tests) {
 my ($x, $op, $y) = @$t;

 cmp_ok $x,      $op, $y;
 cmp_ok int($x), $op, $y;
 cmp_ok $x,      $op, int($y);
 cmp_ok int($x), $op, int($y);

 my $ox = Test::Leaner::TestCmpNum->new($x);
 my $oy = Test::Leaner::TestCmpNum->new($y);

 cmp_ok $ox,     $op, $y;
 cmp_ok $x,      $op, $oy;
 cmp_ok $ox,     $op, $oy;
}

{
 package Test::Leaner::TestCmpStr;

 use overload 'cmp' => sub {
  my ($x, $y, $r) = @_;

  $x = $x->{str};
  $y = $y->{str} if ref $y;

  ($x, $y) = ($y, $x) if $r;

  return $x cmp $y;
 };

 sub new {
  my $class = shift;

  bless { str => $_[0] }, $class
 }
}

my @str_tests = (
 [ 'a', 'eq', 'a' ],
 [ 'a', 'le', 'b' ],
 [ 'a', 'lt', 'b' ],
 [ 'b', 'ge', 'a' ],
 [ 'b', 'gt', 'a' ],
 [ 'a', 'ne', 'b' ],
 [ 'b', 'ne', 'a' ],
);

for my $t (@str_tests) {
 my ($x, $op, $y) = @$t;

 cmp_ok $x, $op, $y;

 my $ox = Test::Leaner::TestCmpStr->new($x);
 my $oy = Test::Leaner::TestCmpStr->new($y);

 cmp_ok $ox, $op, $y;
 cmp_ok $x,  $op, $oy;
 cmp_ok $ox, $op, $oy;
}

my @logic_tests = (
 [ 1, 'or',  0 ],
 [ 0, 'or',  1 ],
 [ 1, 'or',  1 ],
 [ 1, 'xor', 0 ],
 [ 0, 'xor', 1 ],
 [ 1, 'and', 1 ],

 [ 1, '||', 0 ],
 [ 0, '||', 1 ],
 [ 1, '||', 1 ],
 [ 1, '&&', 1 ],
);

for my $t (@logic_tests) {
 my ($x, $op, $y) = @$t;
 cmp_ok $x, $op, $y;
}
