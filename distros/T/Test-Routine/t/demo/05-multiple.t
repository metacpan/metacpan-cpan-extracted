#!/bin/env perl
use strict;
use warnings;

use Test::Routine::Util;
use Test::More;

# One of the benefits of building our sets of tests into roles instead of
# classes is that we can re-use them in whatever combination we want.  We can
# break down sets of tests into bits that can be re-used in different cases.
# With classes, this would lead to multiple inheritance or other monstrosities.

# Here's a first Test::Routine.  We use it to make sure that one of our
# fixture's attributes is a numeric id.
{
  package Test::ThingHasID;
  use Test::Routine;
  use Test::More;

  requires 'id';

  test thing_has_numeric_id => sub {
    my ($self) = @_;

    my $id = $self->id;
    like($id, qr/\A[0-9]+\z/, "the thing's id is a string of ascii digits");
  };
}

# A second one ensures that the thing has an associated directory that
# looks like a unix path.
{
  package Test::HasDirectory;
  use Test::Routine;
  use Test::More;

  requires 'dir';

  test thing_has_unix_dir => sub {
    my ($self) = @_;

    my $dir = $self->dir;
    like($dir, qr{\A(?:/\w+)+/?\z}, "thing has a unix-like directory");
  };
}

# We might have one class that is only expected to pass one test:
{
  package JustHasID;
  use Moose;

  has id => (
    is      => 'ro',
    default => sub { 
      my ($self) = @_;
      return Scalar::Util::refaddr($self);
    },
  );
}

# ...and another class that should pass both:
{
  package UnixUser;
  use Moose;

  has id  => (is => 'ro', default => 501);
  has dir => (is => 'ro', default => '/home/users/rjbs');
}

# So far, none of this is new, it's just a slightly different way of factoring
# things we've seen before.  In t/01-demo.t, we wrote distinct test roles and
# classes, and we made our class compose the role explicitly.  This can be
# a useful way to put these pieces together, but we also might want to write
# all these classes and roles as unconnected components and compose them only
# when we're ready to run our tests.  When we do that, we can tell run_tests
# what to put together.
#
# Here, we tell it that we can test JustHasID with Test::ThingHasID:
run_tests(
  "our JustHasID objects have ids",
  [ 'JustHasID', 'Test::ThingHasID' ],
);

# ...but we can run two test routines against our UnixUser class
run_tests(
  "unix users have dirs and ids",
  [ 'UnixUser', 'Test::ThingHasID', 'Test::HasDirectory' ],
);


# We can still use the "attributes to initialize an object," and when doing
# that it may be that we don't care to run all the otherwise applicable tests,
# because they're not interesting in the scenario we're creating.  For
# example...
run_tests(
  "a trailing slash is okay in a directory",
  [ 'UnixUser', 'Test::HasDirectory' ],
  { dir => '/home/meebo/' },
);

# ...and we're done!
done_testing;
