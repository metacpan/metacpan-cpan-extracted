# $Id $

# Test::Plan::need_min_perl_version() tests

use strict;
use warnings FATAL => qw(all);

# don't inherit Test::More::plan()
use Test::More tests  => 8,
               import => ['!plan'];


#---------------------------------------------------------------------
# compilation
#---------------------------------------------------------------------

our $class = qw(Test::Plan);

use_ok ($class);


#---------------------------------------------------------------------
# need_min_perl_version()
#---------------------------------------------------------------------

{
  local @Test::Plan::SkipReasons;

  my $found = need_min_perl_version();

  ok ($found,
      'unspecified version returns true');

  my @expected = ();

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons empty for any version found');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need_min_perl_version(5.004);

  ok ($found,
      '5.004 found (since we require it in Test::Plan)');

  my @expected = ();

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons empty for ok version found');
}

{
  local @Test::Plan::SkipReasons;

  my $found = need_min_perl_version(99999);

  ok (!$found,
      'version too high returns false');

  my @expected = 'perl >= 99999 is required';

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons shows version not high enough');
}

{
  local @Test::Plan::SkipReasons;

  # since warnings are fatal this would die unless caught
  my $found = need_min_perl_version('5.003_07');

  ok ($found,
      'version acceptable returns true without warnings');
}
