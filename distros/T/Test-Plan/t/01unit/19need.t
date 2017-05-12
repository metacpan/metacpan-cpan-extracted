# $Id $

# Test::Plan::need() tests

use strict;
use warnings FATAL => qw(all);

# don't inherit Test::More::plan()
use Test::More tests  => 9,
               import => ['!plan'];


#---------------------------------------------------------------------
# compilation
#---------------------------------------------------------------------

our $class = qw(Test::Plan);

use_ok ($class);


#---------------------------------------------------------------------
# need()
#---------------------------------------------------------------------

{
  local @Test::Plan::SkipReasons;

  my $found = need(need_module('Foo::Zweeble'));

  ok (!$found,
      'non-existent package returns false');

  my @expected = ("cannot find module 'Foo::Zweeble'");

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons populated for a single failure');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need(need_module('CGI'),
                   need_min_perl_version(99999));

  ok (!$found,
      'minimum perl version not met');

  my @expected = 'perl >= 99999 is required';

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons global contains just the single failure');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need(need_module('Foo::Zweeble'),
                   need_min_perl_version(1),
                   skip_reason('custom reason'));

  ok (!$found,
      'mixed found and not found returns false');

  my @expected = ("cannot find module 'Foo::Zweeble'",
                  'custom reason',);

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons populated for mixed success and failure');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need(need_module('CGI'),
                   need_min_module_version('Test::More' => 0.0001),
                   need_min_perl_version(1));

  ok ($found,
      'existent package as array reference returns true');

  my @expected = ();

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons global is empty on success');
}
