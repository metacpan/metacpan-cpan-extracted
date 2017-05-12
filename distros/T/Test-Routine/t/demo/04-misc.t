use Test::Routine;
use Test::Routine::Util;
use Test::More;

use namespace::autoclean;

# One thing that the previous examples didn't show was how to mark tests as
# "skipped" or "todo."  Test::Routine makes -no- provisions for these
# directives.  Instead, it assumes you will use the entirely usable mechanisms
# provided by Test::More.

# This is a normal test.  It is neither skipped nor todo.
test boring_ordinary_tests => sub {
  pass("This is a plain old boring test that always passes.");
  pass("It's here just to remind you what they look like.");
};

# To skip a test, we just add a "skip_all" plan.  Because test methods get run
# in subtests, this skips the whole subtest, but nothing else.
test sample_skip_test => sub {
  plan skip_all => "these tests don't pass, for some reason";

  is(6, 9, "I don't mind.");
};

# To mark a test todo, we just set our local $TODO variable.  Because the test
# is its own block, this works just like it would in any other Test::More test.
test sample_todo_test => sub {
  local $TODO = 'demo of todo';

  is(2 + 2, 5, "we can bend the fabric of reality");
};

run_me;
done_testing;
