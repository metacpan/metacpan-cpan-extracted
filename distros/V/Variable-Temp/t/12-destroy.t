#!perl

use strict;
use warnings;

use Variable::Temp 'set_temp';

use Test::More tests => 16;

use lib 't/lib';
use VPIT::TestHelpers;

my $x_is_destroyed       = 0;
my $x_temp1_is_destroyed = 0;
my $x_temp2_is_destroyed = 0;

{
 my $x = VPIT::TestHelpers::Guard->new(sub {
  is $x_temp1_is_destroyed, 1;
  is $x_temp2_is_destroyed, 1;
  ++$x_is_destroyed;
 });
 is $x_is_destroyed, 0;

 set_temp $x => VPIT::TestHelpers::Guard->new(sub {
  is $x_is_destroyed,       0;
  is $x_temp2_is_destroyed, 1;
  ++$x_temp1_is_destroyed;
 });
 is $x_is_destroyed,       0;
 is $x_temp1_is_destroyed, 0;
 is $x_temp2_is_destroyed, 0;

 set_temp $x => VPIT::TestHelpers::Guard->new(sub {
  is $x_is_destroyed,       0;
  is $x_temp1_is_destroyed, 0;
  ++$x_temp2_is_destroyed;
 });
 is $x_is_destroyed,       0;
 is $x_temp1_is_destroyed, 0;
 is $x_temp2_is_destroyed, 0;
}

is $x_is_destroyed,       1;
is $x_temp1_is_destroyed, 1;
is $x_temp2_is_destroyed, 1;
