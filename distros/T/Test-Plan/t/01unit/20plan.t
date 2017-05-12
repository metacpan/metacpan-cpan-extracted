# $Id $

# Test::Plan::plan()

use strict;
use warnings FATAL => qw(all);

# don't inherit Test::More::plan()
use Test::More tests  => 15,
               import => ['!plan'];


#---------------------------------------------------------------------
# compilation
#---------------------------------------------------------------------

our $class = qw(Test::Plan);

use_ok ($class);


#---------------------------------------------------------------------
# plan()
#---------------------------------------------------------------------

{
  no warnings qw(redefine);
  my @args = ();
  local *Test::Builder::plan = sub { shift; @args = @_ };

  Test::Plan::plan(tests => 3);

  is ($args[0],
      'tests',
      "plan() found 'tests'");

  is ($args[1],
      3,
      'plan() found 3 tests');
}

{
  no warnings qw(redefine);
  my @args = ();
  local *Test::Builder::plan = sub { shift; @args= @_ };

  Test::Plan::plan(tests => 3, sub {0});

  is ($args[0],
      'skip_all',
      "skipping due to cv returning false");

  is ($args[1],
      '',
      'no reason passed to skip_all');
}

{
  no warnings qw(redefine);
  my @args = ();
  local *Test::Builder::plan = sub { shift; @args = @_ };

  Test::Plan::plan(tests => 3, sub {1});

  is ($args[0],
      'tests',
      "plan() found 'tests' with true cv");

  is ($args[1],
      3,
      'plan() found 3 tests with true cv');
}

{
  no warnings qw(redefine);
  my @args = ();
  local *Test::Builder::plan = sub { shift; @args= @_ };

  Test::Plan::plan(tests => 3, ['Foo::Zwazzle']);

  is ($args[0],
      'skip_all',
      "skipping due to array ref of imaginary packages");

  is ($args[1],
      "cannot find module 'Foo::Zwazzle'",
      'unknown module given as reason');
}

{
  no warnings qw(redefine);
  my @args = ();
  local *Test::Builder::plan = sub { shift; @args = @_ };

  Test::Plan::plan(tests => 3, ['CGI']);

  is ($args[0],
      'tests',
      "plan() found 'tests' with array reference");

  is ($args[1],
      3,
      'plan() found 3 tests with array reference');
}

{
  no warnings qw(redefine);
  my @args = ();
  local *Test::Builder::plan = sub { shift; @args= @_ };

  Test::Plan::plan(tests => 3, 0);

  is ($args[0],
      'skip_all',
      "skipping due to false boolean");

  is ($args[1],
      '',
      'no reason passed with false boolean');
}

{
  no warnings qw(redefine);
  my @args = ();
  local *Test::Builder::plan = sub { shift; @args = @_ };

  Test::Plan::plan(tests => 3, 1);

  is ($args[0],
      'tests',
      "plan() found 'tests' with true boolean");

  is ($args[1],
      3,
      'plan() found 3 tests with true boolean');
}
