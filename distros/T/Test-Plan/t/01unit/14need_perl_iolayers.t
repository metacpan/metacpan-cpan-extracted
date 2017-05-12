# $Id $

# Test::Plan::need_perl_iolayers() tests

use strict;
use warnings FATAL => qw(all);

# don't inherit Test::More::plan()
use Test::More tests  => 3,
               import => ['!plan'];


#---------------------------------------------------------------------
# compilation
#---------------------------------------------------------------------

our $class = qw(Test::Plan);

use_ok ($class);


#---------------------------------------------------------------------
# need_perl_iolayers()
#---------------------------------------------------------------------

use Config;

{
  no warnings qw(redefine);
  # the STORE warning appears mandatory in later perls
  local $^W = 0;
  local *Config::STORE = sub { $_[0]->{$_[1]} = $_[2]; };
  local *Config::Config;
  $Config{extensions} = undef;

  my $found = need_perl_iolayers();

  ok (!$found,
      'property not found');
}

{
  no warnings qw(redefine);
  # the STORE warning appears mandatory in later perls
  local $^W = 0;
  local *Config::STORE = sub { $_[0]->{$_[1]} = $_[2]; };
  local *Config::Config;
  $Config{extensions} = 'PerlIO/scalar';

  my $found = need_perl_iolayers();

  ok ($found,
      'property found');
}
