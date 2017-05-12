# Welcome to part two of the Test::Routine demo.  This is showing how you can
# write quick one-off tests without having to write a bunch of .pm files or
# (worse?) embed packages in bare blocks in the odious way that 01-demo.t did.
#
# First off, we use Test::Routine.  As it did before, this turns the current
# package (main!) into a Test::Routine role.  It also has the pleasant
# side-effect of turning on strict and warnings.
use Test::Routine;

# Then we bring in the utils, because we'll want to run_tests later.
use Test::Routine::Util;

# And, finally, we bring in Test::More so that we can use test assertions, and
# namespace::autoclean to clean up after us.
use Test::More;
use namespace::autoclean;

# We're going to give our tests some state.  It's nothing special.
has counter => (
  is  => 'rw',
  isa => 'Int',
  default => 0,
);

# Then another boring but useful hunk of code: a method for our test routine.
sub counter_is_even {
  my ($self) = @_;
  return $self->counter % 2 == 0;
}

# Then we can write some tests, just like we did before.  Here, we're writing
# several tests, and they will be run in the order in which they were defined.
# You can see that they rely on the state being maintained.
test 'start even' => sub {
  my ($self) = @_;
  ok($self->counter_is_even, "we start with an even counter");

  $self->counter( $self->counter + 1);
};

test 'terminate odd' => sub {
  my ($self) = @_;

  ok(! $self->counter_is_even, "the counter is odd, so state was preserved");
  pass("for your information, the counter is " . $self->counter);
};

# Now we can run these tests just by saying "run_me" -- rather than expecting a
# class or role name, it uses the caller.  In this case, the calling package
# (main!) is a Test::Routine, so the runner composes it with Moose::Object,
# instantiating it, and running the tests on the instance.
run_me;

# Since each test run gets its own instance, we can run the test suite again,
# possibly to verify that the test suite is not destructive of some external
# state.
run_me("second run");

# And we can pass in args to use when constructing the object to be tested.
# Given the tests above, we can pick any starting value for "counter" that is
# even.
run_me({ counter => 192 });

# ...and we're done!
done_testing;

# More Test::Routine behavior is demonstrated in t/03-advice.t and t/04-misc.t
# Go have a look at those!
