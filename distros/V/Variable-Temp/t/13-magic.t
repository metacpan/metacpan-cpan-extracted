#!perl

use strict;
use warnings;

use Variable::Temp 'set_temp';

use Test::More;

use lib 't/lib';
use VPIT::TestHelpers;

load_or_skip_all('Variable::Magic', '0.55', undef);

plan tests => 14;

my $replaced = 0;
my $freed    = 0;

my $wiz = Variable::Magic::wizard(
 set  => sub { ++$replaced; () },
 free => sub { ++$freed;    () },
);

{
 my $y = 1;
 &Variable::Magic::cast(\$y, $wiz);
 is $y,        1;
 is $replaced, 0;
 is $freed,    0;

 {
  set_temp $y => 2;
  is $y,        2;
  is $replaced, 1;
  is $freed,    0;

  $y = 3;
  is $y,        3;
  is $replaced, 2;
  is $freed,    0;
 }

 is $y,        1;
 is $replaced, 3;
 is $freed,    0;
}

is $replaced, 3;
is $freed,    1;
