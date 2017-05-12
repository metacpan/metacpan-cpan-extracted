#!/bin/env perl
use strict;
use warnings;

# This test is both a test and an example of how Test::Routine works!  Welcome
# to t/01-demo.t, I will be your guide, rjbs.

{
  # This block defines the HashTester package.  It's a Test::Routine, meaning
  # it's a role.  We define state that the test will need to keep and any
  # requirements we might have.
  #
  # Before we can run this test, we'll need to compose the role into a class so
  # that we can make an instance.
  package HashTester;
  use Test::Routine;

  # We import stuff from Test::More because, well, who wants to re-write all
  # those really useful test routines that exist out there?  Maybe somebody,
  # but not me.
  use Test::More;

  # ...but then we use namespace::autoclean to get rid of the routines once
  # we've bound to them.  This is just standard Moose practice, anyway, right?
  use namespace::autoclean;

  # Finally, some state!  Every test will get called as method on an instance,
  # and it will have this attribute.  Here are some points of interest:
  #
  # - We're giving this attribute a builder, so it will try to get built with a
  #   call to $self->build_hash_to_test -- so each class that composes this
  #   role can provide means for these attributes (fixtures) to be generated as
  #   needed.
  #
  # - We are not adding "requires 'build_hash_to_test'", because then we can
  #   apply this role to Moose::Object and instantiate it with a given value
  #   in the constructor.  There will be an example of this below.  This lets
  #   us re-use these tests in many variations without having to write class
  #   after class.
  #
  # - We don't use lazy_build because it would create a clearer.  If someone
  #   then cleared our lazy_build fixture, it could not be re-built in the
  #   event that we'd gotten it explicitly from the constructor!
  #
  # Using Moose attributes for our state and fixtures allows us to get all of
  # their powerful behaviors like types, delegation, traits, and so on, and
  # allows us to decompose shared behavior into roles.
  #
  has hash_to_test => (
    is  => 'ro',
    isa => 'HashRef',
    builder => 'build_hash_to_test',
  );

  # Here, we're just declaring an actual test that we will run.  This sub will
  # get installed as a method with a name that won't get clobbered easily.  The
  # method will be found later by run_tests so we can find and execute all
  # tests on an instance.
  #
  # There is nothing magical about this method!  Calling this method is
  # performed in a Test::More subtest block.  A TAP plan can be issued with
  # "plan", and we can issue TODO or SKIP directives the same way.  There is
  # none of the return-to-skip magic that we find in Test::Class.
  #
  # The string after "test" is used as the method name -- which means we're
  # getting a method name with spaces in it.  This can be slightly problematic
  # if you try to use, say, ::, in a method name.  For the most part, it works
  # quite well -- but look at the next test for an example of how to give an
  # explicit description.
  test "only one key in hash" => sub {
    my ($self) = @_;

    my $hash = $self->hash_to_test;

    is(keys %$hash, 1, "we have one key in our test hash");
    is(2+2, 4, "universe still okay");
  };

  # The only thing of note here is that we're passing a hashref of extra args
  # to the test method constructor.  "desc" lets us set the test's description,
  # which is used in the test output, so we can avoid weird method names being
  # installed.  Also note that we order tests more or less by order of
  # definition, not by name or description.
  test second_test => { desc => "Test::Routine demo!" } => sub {
    pass("We're running this test second");
    pass("...notice that the subtest's label is the 'desc' above");
    pass("...and not the method name!");
  };
}

{
  # This package is one fixture against which we can run the HashTester
  # routine.  It has the only thing it needs:  a build_hash_to_test method.
  # Obviously real examples would have more to them than this.
  package ProcessHash;
  use Moose;
  with 'HashTester';

  use namespace::autoclean;

  sub build_hash_to_test { return { $$ => $^T } }
}

# Now we're into the body of the test program:  where tests actually get run.

# We use Test::Routine::Util to get its "run_tests" routine, which runs the
# tests on an instance, building it if needed.
use Test::Routine::Util;

# We use Test::More to get done_testing.  We don't assume that run_tests is the
# entire test, because that way we can (as we do here) run multiple test
# instances, and can intersperse other kinds of sanity checks amongst the
# Test::Routine-style tests.
use Test::More;

is(2+2, 4, "universe still makes sense") or BAIL_OUT("PANIC!");

# The first arg is a description for the subtest that will be run.  The second,
# here, is a class that will be instantiated and tested.
run_tests('ProcessHash class' => 'ProcessHash');

# Here, the second argument is an instance of a class to test.
run_tests('ProcessHash obj' => ProcessHash->new({ hash_to_test => { 1 => 0 }}));

# We could also just supply a class name and a set of args to pass to new.
# The below is very nearly equivalent to the above:
run_tests('ProcessHash new' => ProcessHash => { hash_to_test => { 1 => 0 }});

# ...and here, the second arg is not a class or instance at all, but the
# Test::Routine role (by name).  Since we know we can't instantiate a role,
# run_tests will try to compose it with Moose::Object.  Then the args are used
# as the args to ->new on the new class, as above.  This lets us write
# Test::Routines that can be tested with the right state to start with, or
# Test::Routines that need to be composed with testing fixture classes.
run_tests(
  'HashTester with given state',
  HashTester => {
    hash_to_test => { a => 1 },
  },
);

# There's one more interesting way to run out tests, but it's demonstrated in
# 02-simple.t instead of here.  Go check that out.

# ...and we're done!
done_testing;
