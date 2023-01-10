use v5.12.0;
use warnings;
package Test::Routine::Manual::Demo 0.030;
# ABSTRACT: a walkthrough, in code, of Test::Routine

#pod =head1 The Demo
#pod
#pod =head2 t/demo/01-demo.t
#pod
#pod   #!/bin/env perl
#pod   use strict;
#pod   use warnings;
#pod   
#pod   # This test is both a test and an example of how Test::Routine works!  Welcome
#pod   # to t/01-demo.t, I will be your guide, rjbs.
#pod   
#pod   {
#pod     # This block defines the HashTester package.  It's a Test::Routine, meaning
#pod     # it's a role.  We define state that the test will need to keep and any
#pod     # requirements we might have.
#pod     #
#pod     # Before we can run this test, we'll need to compose the role into a class so
#pod     # that we can make an instance.
#pod     package HashTester;
#pod     use Test::Routine;
#pod   
#pod     # We import stuff from Test::More because, well, who wants to re-write all
#pod     # those really useful test routines that exist out there?  Maybe somebody,
#pod     # but not me.
#pod     use Test::More;
#pod   
#pod     # ...but then we use namespace::autoclean to get rid of the routines once
#pod     # we've bound to them.  This is just standard Moose practice, anyway, right?
#pod     use namespace::autoclean;
#pod   
#pod     # Finally, some state!  Every test will get called as method on an instance,
#pod     # and it will have this attribute.  Here are some points of interest:
#pod     #
#pod     # - We're giving this attribute a builder, so it will try to get built with a
#pod     #   call to $self->build_hash_to_test -- so each class that composes this
#pod     #   role can provide means for these attributes (fixtures) to be generated as
#pod     #   needed.
#pod     #
#pod     # - We are not adding "requires 'build_hash_to_test'", because then we can
#pod     #   apply this role to Moose::Object and instantiate it with a given value
#pod     #   in the constructor.  There will be an example of this below.  This lets
#pod     #   us re-use these tests in many variations without having to write class
#pod     #   after class.
#pod     #
#pod     # - We don't use lazy_build because it would create a clearer.  If someone
#pod     #   then cleared our lazy_build fixture, it could not be re-built in the
#pod     #   event that we'd gotten it explicitly from the constructor!
#pod     #
#pod     # Using Moose attributes for our state and fixtures allows us to get all of
#pod     # their powerful behaviors like types, delegation, traits, and so on, and
#pod     # allows us to decompose shared behavior into roles.
#pod     #
#pod     has hash_to_test => (
#pod       is  => 'ro',
#pod       isa => 'HashRef',
#pod       builder => 'build_hash_to_test',
#pod     );
#pod   
#pod     # Here, we're just declaring an actual test that we will run.  This sub will
#pod     # get installed as a method with a name that won't get clobbered easily.  The
#pod     # method will be found later by run_tests so we can find and execute all
#pod     # tests on an instance.
#pod     #
#pod     # There is nothing magical about this method!  Calling this method is
#pod     # performed in a Test::More subtest block.  A TAP plan can be issued with
#pod     # "plan", and we can issue TODO or SKIP directives the same way.  There is
#pod     # none of the return-to-skip magic that we find in Test::Class.
#pod     #
#pod     # The string after "test" is used as the method name -- which means we're
#pod     # getting a method name with spaces in it.  This can be slightly problematic
#pod     # if you try to use, say, ::, in a method name.  For the most part, it works
#pod     # quite well -- but look at the next test for an example of how to give an
#pod     # explicit description.
#pod     test "only one key in hash" => sub {
#pod       my ($self) = @_;
#pod   
#pod       my $hash = $self->hash_to_test;
#pod   
#pod       is(keys %$hash, 1, "we have one key in our test hash");
#pod       is(2+2, 4, "universe still okay");
#pod     };
#pod   
#pod     # The only thing of note here is that we're passing a hashref of extra args
#pod     # to the test method constructor.  "desc" lets us set the test's description,
#pod     # which is used in the test output, so we can avoid weird method names being
#pod     # installed.  Also note that we order tests more or less by order of
#pod     # definition, not by name or description.
#pod     test second_test => { desc => "Test::Routine demo!" } => sub {
#pod       pass("We're running this test second");
#pod       pass("...notice that the subtest's label is the 'desc' above");
#pod       pass("...and not the method name!");
#pod     };
#pod   }
#pod   
#pod   {
#pod     # This package is one fixture against which we can run the HashTester
#pod     # routine.  It has the only thing it needs:  a build_hash_to_test method.
#pod     # Obviously real examples would have more to them than this.
#pod     package ProcessHash;
#pod     use Moose;
#pod     with 'HashTester';
#pod   
#pod     use namespace::autoclean;
#pod   
#pod     sub build_hash_to_test { return { $$ => $^T } }
#pod   }
#pod   
#pod   # Now we're into the body of the test program:  where tests actually get run.
#pod   
#pod   # We use Test::Routine::Util to get its "run_tests" routine, which runs the
#pod   # tests on an instance, building it if needed.
#pod   use Test::Routine::Util;
#pod   
#pod   # We use Test::More to get done_testing.  We don't assume that run_tests is the
#pod   # entire test, because that way we can (as we do here) run multiple test
#pod   # instances, and can intersperse other kinds of sanity checks amongst the
#pod   # Test::Routine-style tests.
#pod   use Test::More;
#pod   
#pod   is(2+2, 4, "universe still makes sense") or BAIL_OUT("PANIC!");
#pod   
#pod   # The first arg is a description for the subtest that will be run.  The second,
#pod   # here, is a class that will be instantiated and tested.
#pod   run_tests('ProcessHash class' => 'ProcessHash');
#pod   
#pod   # Here, the second argument is an instance of a class to test.
#pod   run_tests('ProcessHash obj' => ProcessHash->new({ hash_to_test => { 1 => 0 }}));
#pod   
#pod   # We could also just supply a class name and a set of args to pass to new.
#pod   # The below is very nearly equivalent to the above:
#pod   run_tests('ProcessHash new' => ProcessHash => { hash_to_test => { 1 => 0 }});
#pod   
#pod   # ...and here, the second arg is not a class or instance at all, but the
#pod   # Test::Routine role (by name).  Since we know we can't instantiate a role,
#pod   # run_tests will try to compose it with Moose::Object.  Then the args are used
#pod   # as the args to ->new on the new class, as above.  This lets us write
#pod   # Test::Routines that can be tested with the right state to start with, or
#pod   # Test::Routines that need to be composed with testing fixture classes.
#pod   run_tests(
#pod     'HashTester with given state',
#pod     HashTester => {
#pod       hash_to_test => { a => 1 },
#pod     },
#pod   );
#pod   
#pod   # There's one more interesting way to run out tests, but it's demonstrated in
#pod   # 02-simple.t instead of here.  Go check that out.
#pod   
#pod   # ...and we're done!
#pod   done_testing;
#pod
#pod
#pod =head2 t/demo/02-simple.t
#pod
#pod   # Welcome to part two of the Test::Routine demo.  This is showing how you can
#pod   # write quick one-off tests without having to write a bunch of .pm files or
#pod   # (worse?) embed packages in bare blocks in the odious way that 01-demo.t did.
#pod   #
#pod   # First off, we use Test::Routine.  As it did before, this turns the current
#pod   # package (main!) into a Test::Routine role.  It also has the pleasant
#pod   # side-effect of turning on strict and warnings.
#pod   use Test::Routine;
#pod   
#pod   # Then we bring in the utils, because we'll want to run_tests later.
#pod   use Test::Routine::Util;
#pod   
#pod   # And, finally, we bring in Test::More so that we can use test assertions, and
#pod   # namespace::autoclean to clean up after us.
#pod   use Test::More;
#pod   use namespace::autoclean;
#pod   
#pod   # We're going to give our tests some state.  It's nothing special.
#pod   has counter => (
#pod     is  => 'rw',
#pod     isa => 'Int',
#pod     default => 0,
#pod   );
#pod   
#pod   # Then another boring but useful hunk of code: a method for our test routine.
#pod   sub counter_is_even {
#pod     my ($self) = @_;
#pod     return $self->counter % 2 == 0;
#pod   }
#pod   
#pod   # Then we can write some tests, just like we did before.  Here, we're writing
#pod   # several tests, and they will be run in the order in which they were defined.
#pod   # You can see that they rely on the state being maintained.
#pod   test 'start even' => sub {
#pod     my ($self) = @_;
#pod     ok($self->counter_is_even, "we start with an even counter");
#pod   
#pod     $self->counter( $self->counter + 1);
#pod   };
#pod   
#pod   test 'terminate odd' => sub {
#pod     my ($self) = @_;
#pod   
#pod     ok(! $self->counter_is_even, "the counter is odd, so state was preserved");
#pod     pass("for your information, the counter is " . $self->counter);
#pod   };
#pod   
#pod   # Now we can run these tests just by saying "run_me" -- rather than expecting a
#pod   # class or role name, it uses the caller.  In this case, the calling package
#pod   # (main!) is a Test::Routine, so the runner composes it with Moose::Object,
#pod   # instantiating it, and running the tests on the instance.
#pod   run_me;
#pod   
#pod   # Since each test run gets its own instance, we can run the test suite again,
#pod   # possibly to verify that the test suite is not destructive of some external
#pod   # state.
#pod   run_me("second run");
#pod   
#pod   # And we can pass in args to use when constructing the object to be tested.
#pod   # Given the tests above, we can pick any starting value for "counter" that is
#pod   # even.
#pod   run_me({ counter => 192 });
#pod   
#pod   # ...and we're done!
#pod   done_testing;
#pod   
#pod   # More Test::Routine behavior is demonstrated in t/03-advice.t and t/04-misc.t
#pod   # Go have a look at those!
#pod
#pod
#pod =head2 t/demo/03-advice.t
#pod
#pod   use Test::Routine;
#pod   use Test::Routine::Util;
#pod   use Test::More;
#pod   
#pod   use namespace::autoclean;
#pod   
#pod   # xUnit style testing has the idea of setup and teardown that happens around
#pod   # each test.  With Test::Routine, we assume that you will do most of this sort
#pod   # of thing in your BUILD, DEMOLISH, and attribute management.  Still, you can
#pod   # easily do setup and teardown by applying method modifiers to the "run_test"
#pod   # method, which your Test::Routine uses to run each test.  Here's a simple
#pod   # example.
#pod   
#pod   # We have the same boring state that we saw before.  It's just an integer that
#pod   # is carried over between tests.
#pod   has counter => (
#pod     is   => 'rw',
#pod     isa  => 'Int',
#pod     lazy => 1,
#pod     default => 0,
#pod     clearer => 'clear_counter',
#pod   );
#pod   
#pod   # The first test changes the counter's value and leaves it changed.
#pod   test test_0 => sub {
#pod     my ($self) = @_;
#pod   
#pod     is($self->counter, 0, 'start with counter = 0');
#pod     $self->counter( $self->counter + 1);
#pod     is($self->counter, 1, 'end with counter = 1');
#pod   };
#pod   
#pod   # The second test assumes that the value is the default, again.  We want to
#pod   # make sure that before each test, the counter is reset, but we don't want to
#pod   # tear down and recreate the whole object, because it may have other, more
#pod   # expensive resources built.
#pod   test test_1 => sub {
#pod     my ($self) = @_;
#pod   
#pod     is($self->counter, 0, 'counter is reset between tests');
#pod   };
#pod   
#pod   # ...so we apply a "before" modifier to each test run, calling the clearer on
#pod   # the counter.  When next accessed, it will re-initialize to zero.  We could
#pod   # call any other code we want here, and we can compose numerous modifiers
#pod   # together onto run_test.
#pod   #
#pod   # If you want to clear *all* the object state between each test... you probably
#pod   # want to refactor.
#pod   before run_test => sub { $_[0]->clear_counter };
#pod   
#pod   run_me;
#pod   done_testing;
#pod
#pod
#pod =head2 t/demo/04-misc.t
#pod
#pod   use Test::Routine;
#pod   use Test::Routine::Util;
#pod   use Test::More;
#pod   
#pod   use namespace::autoclean;
#pod   
#pod   # One thing that the previous examples didn't show was how to mark tests as
#pod   # "skipped" or "todo."  Test::Routine makes -no- provisions for these
#pod   # directives.  Instead, it assumes you will use the entirely usable mechanisms
#pod   # provided by Test::More.
#pod   
#pod   # This is a normal test.  It is neither skipped nor todo.
#pod   test boring_ordinary_tests => sub {
#pod     pass("This is a plain old boring test that always passes.");
#pod     pass("It's here just to remind you what they look like.");
#pod   };
#pod   
#pod   # To skip a test, we just add a "skip_all" plan.  Because test methods get run
#pod   # in subtests, this skips the whole subtest, but nothing else.
#pod   test sample_skip_test => sub {
#pod     plan skip_all => "these tests don't pass, for some reason";
#pod   
#pod     is(6, 9, "I don't mind.");
#pod   };
#pod   
#pod   # To mark a test todo, we just set our local $TODO variable.  Because the test
#pod   # is its own block, this works just like it would in any other Test::More test.
#pod   test sample_todo_test => sub {
#pod     local $TODO = 'demo of todo';
#pod   
#pod     is(2 + 2, 5, "we can bend the fabric of reality");
#pod   };
#pod   
#pod   run_me;
#pod   done_testing;
#pod
#pod
#pod =head2 t/demo/05-multiple.t
#pod
#pod   #!/bin/env perl
#pod   use strict;
#pod   use warnings;
#pod   
#pod   use Test::Routine::Util;
#pod   use Test::More;
#pod   
#pod   # One of the benefits of building our sets of tests into roles instead of
#pod   # classes is that we can re-use them in whatever combination we want.  We can
#pod   # break down sets of tests into bits that can be re-used in different cases.
#pod   # With classes, this would lead to multiple inheritance or other monstrosities.
#pod   
#pod   # Here's a first Test::Routine.  We use it to make sure that one of our
#pod   # fixture's attributes is a numeric id.
#pod   {
#pod     package Test::ThingHasID;
#pod     use Test::Routine;
#pod     use Test::More;
#pod   
#pod     requires 'id';
#pod   
#pod     test thing_has_numeric_id => sub {
#pod       my ($self) = @_;
#pod   
#pod       my $id = $self->id;
#pod       like($id, qr/\A[0-9]+\z/, "the thing's id is a string of ascii digits");
#pod     };
#pod   }
#pod   
#pod   # A second one ensures that the thing has an associated directory that
#pod   # looks like a unix path.
#pod   {
#pod     package Test::HasDirectory;
#pod     use Test::Routine;
#pod     use Test::More;
#pod   
#pod     requires 'dir';
#pod   
#pod     test thing_has_unix_dir => sub {
#pod       my ($self) = @_;
#pod   
#pod       my $dir = $self->dir;
#pod       like($dir, qr{\A(?:/\w+)+/?\z}, "thing has a unix-like directory");
#pod     };
#pod   }
#pod   
#pod   # We might have one class that is only expected to pass one test:
#pod   {
#pod     package JustHasID;
#pod     use Moose;
#pod   
#pod     has id => (
#pod       is      => 'ro',
#pod       default => sub {
#pod         my ($self) = @_;
#pod         return Scalar::Util::refaddr($self);
#pod       },
#pod     );
#pod   }
#pod   
#pod   # ...and another class that should pass both:
#pod   {
#pod     package UnixUser;
#pod     use Moose;
#pod   
#pod     has id  => (is => 'ro', default => 501);
#pod     has dir => (is => 'ro', default => '/home/users/rjbs');
#pod   }
#pod   
#pod   # So far, none of this is new, it's just a slightly different way of factoring
#pod   # things we've seen before.  In t/01-demo.t, we wrote distinct test roles and
#pod   # classes, and we made our class compose the role explicitly.  This can be
#pod   # a useful way to put these pieces together, but we also might want to write
#pod   # all these classes and roles as unconnected components and compose them only
#pod   # when we're ready to run our tests.  When we do that, we can tell run_tests
#pod   # what to put together.
#pod   #
#pod   # Here, we tell it that we can test JustHasID with Test::ThingHasID:
#pod   run_tests(
#pod     "our JustHasID objects have ids",
#pod     [ 'JustHasID', 'Test::ThingHasID' ],
#pod   );
#pod   
#pod   # ...but we can run two test routines against our UnixUser class
#pod   run_tests(
#pod     "unix users have dirs and ids",
#pod     [ 'UnixUser', 'Test::ThingHasID', 'Test::HasDirectory' ],
#pod   );
#pod   
#pod   
#pod   # We can still use the "attributes to initialize an object," and when doing
#pod   # that it may be that we don't care to run all the otherwise applicable tests,
#pod   # because they're not interesting in the scenario we're creating.  For
#pod   # example...
#pod   run_tests(
#pod     "a trailing slash is okay in a directory",
#pod     [ 'UnixUser', 'Test::HasDirectory' ],
#pod     { dir => '/home/meebo/' },
#pod   );
#pod   
#pod   # ...and we're done!
#pod   done_testing;
#pod
#pod
#pod
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine::Manual::Demo - a walkthrough, in code, of Test::Routine

=head1 VERSION

version 0.030

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 The Demo

=head2 t/demo/01-demo.t

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

=head2 t/demo/02-simple.t

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

=head2 t/demo/03-advice.t

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

=head2 t/demo/04-misc.t

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

=head2 t/demo/05-multiple.t

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

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
