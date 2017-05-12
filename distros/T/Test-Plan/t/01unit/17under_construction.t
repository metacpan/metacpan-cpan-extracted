# $Id $

# Test::Plan::under_construction() tests

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
# under_construction()
#---------------------------------------------------------------------

{
  local @Test::Plan::SkipReasons;

  my $ok = under_construction();

  ok (!$ok,
      'under_construction() returns false');

  my @expected = 'This test is under construction';

  is_deeply (\@Test::Plan::SkipReasons,
             \@expected,
             '@SkipReasons under construction');
}
