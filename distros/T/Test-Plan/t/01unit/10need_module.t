# $Id $

# Test::Plan::need_module() tests

use strict;
use warnings FATAL => qw(all);

# don't inherit Test::More::plan()
use Test::More tests  => 11,
               import => ['!plan'];


#---------------------------------------------------------------------
# compilation
#---------------------------------------------------------------------

our $class = qw(Test::Plan);

use_ok ($class);


#---------------------------------------------------------------------
# need_module()
#---------------------------------------------------------------------

{
  local @Test::Plan::SkipReasons;

  my $found = need_module('Foo::Zweeble');

  ok (!$found,
      'non-existent package returns false');

  my @expected = ("cannot find module 'Foo::Zweeble'");

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons populated for a single failure');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need_module('CGI');  # part of 5.004 and beyond

  ok ($found,
      'existent package returns true');

  my @expected = ();

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons global is empty on success');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need_module('Foo::Zweeble',
                          'CGI',
                          'Foo::Zwabble');

  ok (!$found,
      'mixed found and not found returns false');

  my @expected = ("cannot find module 'Foo::Zweeble'",
                  "cannot find module 'Foo::Zwabble'",);

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons populated for mixed success and failure');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need_module(['CGI']);

  ok ($found,
      'existent package as array reference returns true');

  my @expected = ();

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons global is empty on success');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need_module([ 'Foo::Zweeble',
                            'CGI',
                            'Foo::Zwabble'
                          ]);

  ok (!$found,
      'mixed found and not found as array reference returns false');

  my @expected = ("cannot find module 'Foo::Zweeble'",
                  "cannot find module 'Foo::Zwabble'",);

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons populated for mixed success and failure');
}

