use Test::Routine;
use Test::Routine::Util;
use Test::More;

use namespace::autoclean;

# xUnit style testing has the idea of setup and teardown that happens around
# each test.  With Test::Routine, we assume that you will do most of this sort
# of thing in your BUILD, DEMOLISH, and attribute management.  Still, you can
# easily do setup and teardown by applying method modifiers to the "run_test"
# method, which your Test::Routine uses to run each test.  Here's a simple
# example.

# We have the same boring state that we saw before.  It's just an integer that
# is carried over between tests.
has counter => (
  is   => 'rw',
  isa  => 'Int',
  lazy => 1,
  default => 0,
  clearer => 'clear_counter',
);

# The first test changes the counter's value and leaves it changed.
test test_0 => sub {
  my ($self) = @_;

  is($self->counter, 0, 'start with counter = 0');
  $self->counter( $self->counter + 1);
  is($self->counter, 1, 'end with counter = 1');
};

# The second test assumes that the value is the default, again.  We want to
# make sure that before each test, the counter is reset, but we don't want to
# tear down and recreate the whole object, because it may have other, more
# expensive resources built.
test test_1 => sub {
  my ($self) = @_;

  is($self->counter, 0, 'counter is reset between tests');
};

# ...so we apply a "before" modifier to each test run, calling the clearer on
# the counter.  When next accessed, it will re-initialize to zero.  We could
# call any other code we want here, and we can compose numerous modifiers
# together onto run_test.
#
# If you want to clear *all* the object state between each test... you probably
# want to refactor.
before run_test => sub { $_[0]->clear_counter };

run_me;
done_testing;
