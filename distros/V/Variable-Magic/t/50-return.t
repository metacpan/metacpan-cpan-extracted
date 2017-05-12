#!perl -T

use strict;
use warnings;

use Variable::Magic qw<wizard cast dispell getdata>;

use Test::More tests => 3 * 11;

our $destroyed;

my $destructor = wizard free => sub { ++$destroyed; return };

{
 my $increment;

 my $increment_aux = wizard(
  data => sub { $_[1] },
  free => sub {
   my ($target) = $_[1];
   my $target_data = &getdata($target, $increment);
   local $target_data->{guard} = 1;
   ++$$target;
   return;
  },
 );

 $increment = wizard(
  data => sub {
   return +{ guard => 0 };
  },
  set  => sub {
   return if $_[1]->{guard};
   my $token;
   cast $token, $increment_aux, $_[0];
   return \$token;
  },
 );

 local $destroyed = 0;

 {
  my $x = 0;

  cast $x, $destructor;

  {
   cast $x, $increment;
   is $x, 0;
   $x = 1;
   is $x, 2;
   $x = 123;
   is $x, 124;
   $x = -5;
   is $x, -4;
   $x = 27, is($x, 27);
   is $x, 28;
   my @y = ($x = -13, $x);
   is $x, -12;
   is "@y", '-13 -13';
  }

  dispell $x, $increment;

  $x = 456;
  is $x, 456;

  is $destroyed, 0;
 }

 is $destroyed, 1;
}

{
 my $locker;

 my $locker_aux = wizard(
  data => sub { $_[1] },
  free => sub {
   my ($target) = $_[1];
   my $target_data = &getdata($target, $locker);
   local $target_data->{guard} = 1;
   $$target = $target_data->{value};
   return;
  },
 );

 $locker = wizard(
  data => sub {
   return +{ guard => 0, value => $_[1] };
  },
  set  => sub {
   return if $_[1]->{guard};
   my $token;
   cast $token, $locker_aux, $_[0];
   return \$token;
  },
 );

 local $destroyed = 0;

 {
  my $x = 0;

  cast $x, $destructor;

  {
   cast $x, $locker, 999;
   is $x, 0;
   $x = 1;
   is $x, 999;
   $x = 123;
   is $x, 999;
   $x = -5;
   is $x, 999;
   $x = 27, is($x, 27);
   is $x, 999;
   my @y = ($x = -13, $x);
   is $x, 999;
   is "@y", '-13 -13';
  }

  dispell $x, $locker;

  $x = 456;
  is $x, 456;

  is $destroyed, 0;
 }

 is $destroyed, 1;
}

{
 my $delayed;

 my $delayed_aux = wizard(
  data => sub { $_[1] },
  free => sub {
   my ($target) = $_[1];
   my $target_data = &getdata($target, $delayed);
   local $target_data->{guard} = 1;
   if (ref $target eq 'SCALAR') {
    my $orig = $$target;
    $$target = $target_data->{mangler}->($orig);
   }
   return;
  },
 );

 $delayed = wizard(
  data => sub {
   return +{ guard => 0, mangler => $_[1] };
  },
  set  => sub {
   return if $_[1]->{guard};
   my $token;
   cast $token, $delayed_aux, $_[0];
   return \$token;
  },
 );

 local $destroyed = 0;

 {
  my $x = 0;

  cast $x, $destructor;

  {
   cast $x, $delayed => sub { $_[0] * 2 };
   is $x, 0;
   $x = 1;
   is $x, 2;
   $x = 123;
   is $x, 246;
   $x = -5;
   is $x, -10;
   $x = 27, is($x, 27);
   is $x, 54;
   my @y = ($x = -13, $x);
   is $x, -26;
   is "@y", '-13 -13';
  }

  dispell $x, $delayed;

  $x = 456;
  is $x, 456;

  is $destroyed, 0;
 }

 is $destroyed, 1;
}
