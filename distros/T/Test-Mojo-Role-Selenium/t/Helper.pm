package t::Helper;

use Mojo::Base -strict;
use Mojo::Util 'monkey_patch';
use Test::Mojo;
use Test::More ();

our $x = 0;

sub mock_driver {
  return state $driver = eval <<'HERE' || die $@;
  package t::Selenium::MockDriver;
  sub debug_on {}
  sub default_finder {}
  sub get {}
  sub new {shift; return bless {@_}, 't::Selenium::MockDriver'}
  sub x { $x++ }
  $INC{'t/Selenium/MockDriver.pm'} = 't::Selenium::MockDriver';
HERE
}

sub t {
  my $class = shift;
  return Test::Mojo->with_roles('+Selenium')->new(@_);
}

sub import {
  my $class  = shift;
  my $caller = caller;

  strict->import;
  warnings->import;

  eval <<"HERE" or die $@;
  package $caller;
  use Test::More;
  1;
HERE
}

1;
