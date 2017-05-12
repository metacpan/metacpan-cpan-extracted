# $Id $

# Test::Plan::skip_reason() tests

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
# skip_reason()
#---------------------------------------------------------------------

{
  local @Test::Plan::SkipReasons;

  my @reason = 'some fancy reason';

  my $ok = skip_reason($reason[0]);

  ok (!$ok,
      'skip_reason() returns false');

  is_deeply (\@Test::Plan::SkipReasons,
             \@reason,
             '@SkipReasons holds custom reason');
}
