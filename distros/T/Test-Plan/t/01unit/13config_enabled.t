# $Id $

# Test::Plan::config_enabled() tests

use strict;
use warnings FATAL => qw(all);

# don't inherit Test::More::plan()
use Test::More tests  => 5,
               import => ['!plan'];


#---------------------------------------------------------------------
# compilation
#---------------------------------------------------------------------

our $class = qw(Test::Plan);

use_ok ($class);


#---------------------------------------------------------------------
# Test::Plan::config_enabled()
#---------------------------------------------------------------------

use Config;

{
  # something we know not to be enabled in any perl (I hope)
  my $found = Test::Plan::config_enabled('foo');

  ok (!$found,
      'foo not configured');
}

{
  no warnings qw(redefine);
  local *Config::STORE = sub { $_[0]->{$_[1]} = $_[2]; };
  local $Config{useithreads};

  my $found = Test::Plan::config_enabled('useithreads');

  ok (!$found,
      'property not found');
}

{
  no warnings qw(redefine);
  local *Config::STORE = sub { $_[0]->{$_[1]} = $_[2]; };
  local $Config{useithreads} = 'foo';

  my $found = Test::Plan::config_enabled('useithreads');

  ok (!$found,
      'property found but not defined');
}

{
  no warnings qw(redefine);
  local *Config::STORE = sub { $_[0]->{$_[1]} = $_[2]; };
  local $Config{useithreads} = 'define';

  my $found = Test::Plan::config_enabled('useithreads');

  ok ($found,
      'property found and defined');
}
