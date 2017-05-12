# $Id $

# Test::Plan::need_min_module_version() tests

use strict;
use warnings FATAL => qw(all);

# don't inherit Test::More::plan()
use Test::More tests  => 10,
               import => ['!plan'];


#---------------------------------------------------------------------
# compilation
#---------------------------------------------------------------------

our $class = qw(Test::Plan);

use_ok ($class);


#---------------------------------------------------------------------
# need_min_module_version()
#---------------------------------------------------------------------

{
  local @Test::Plan::SkipReasons;

  my $found = need_min_module_version('Foo::Zweeble');

  ok (!$found,
      'non-existent package returns false');

  my @expected = ("cannot find module 'Foo::Zweeble'");

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons shows module not found');
}

{
  local @Test::Plan::SkipReasons;

  # part of 5.004 and beyond
  my $found = need_min_module_version('CGI');

  ok ($found,
      'existent package without version returns true');

  my @expected = ();

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons global is empty on success');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need_min_module_version(CGI => 99999);

  ok (!$found,
      'version too high returns false');

  my @expected = 'CGI version 99999 or higher is required';

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons shows version not high enough');
}

{
  local @Test::Plan::SkipReasons;

  # version from 5.004
  my $found = need_min_module_version(CGI => 2.36);

  ok ($found,
      'version acceptable returns true');

  my @expected = ();

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons empty for version ok');
}

{
  local @Test::Plan::SkipReasons;

  # since warnings are fatal this would die unless caught
  my $found = need_min_module_version(CGI => '0.18_01');

  ok ($found,
      'version acceptable returns true without warnings');
}
