#!perl

use strict;
use warnings;

use Variable::Temp 'temp';

use Test::More;

BEGIN {
 if ("$]" >= 5.016) {
  plan tests => 12;
 } else {
  plan skip_all => 'perl 5.16 required to have \$ proto accept sub entries';
 }
}

{
 package Variable::Temp::TestPkg;

 sub new {
  my ($class, $val) = @_;

  bless { value => $val }, $class;
 }

 sub value :lvalue {
  $_[0]->{value}
 }

 sub is_value {
  my ($self, $expected, $desc) = @_;
  ::is($self->{value}, $expected, $desc);
 }
}

my $x = Variable::Temp::TestPkg->new(1);
$x->is_value(1);

{
 temp $x->value = 2;
 $x->is_value(2);
}

$x->is_value(1);

{
 temp $x->value = 3;
 $x->is_value(3);

 temp $x->value = 4;
 $x->is_value(4);
}

$x->is_value(1);

{
 temp $x->value = 5;
 $x->is_value(5);

 {
  temp $x->value = 6;
  $x->is_value(6);
 }

 $x->is_value(5);
}

$x->is_value(1);

{
 temp $x->value;
 $x->is_value(undef);
}

$x->is_value(1);
