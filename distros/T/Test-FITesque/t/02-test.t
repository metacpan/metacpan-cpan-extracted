#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 24;
use Test::Exception;

use lib 't/lib';
BEGIN {
  use_ok q{Test::FITesque::Test};
}
can_ok q{Test::FITesque::Test}, qw(new add test_count run_tests);

use lib 't/mock';
use Test::FakeBuilder;
$Test::FITesque::Test::TEST_BUILDER = Test::FakeBuilder->new();

Basic_usage: {
  my $test = Test::FITesque::Test->new();
  isa_ok $test, q{Test::FITesque::Test};

  # Add first row relating to fixture object construction
  is $test->test_count(), 0, q{No tests yet};
  $test->add(qw(Buddha::TestFixture));
  is $test->test_count(), 0, q{No tests yet};

  # Add a test row
  $test->add(qw(one two three));
  is $test->test_count(), 3, q{Single test row with 3 TAP tests};

  # Add another test row
  $test->add(qw(apple box cat));
  is $test->test_count(), 4, q{Single test row with 1 TAP test};
  
  # Re-add a row
  $test->add(qw(one hehe haha));
  is $test->test_count(), 7, q{Single test row with 3 TAP tests};

  $test->run_tests();
  is_deeply $Buddha::TestFixture::RECORDED, [
    [qw(ONE two three)],
    [qw(APPLE box cat)],
    [qw(ONE hehe haha)],
  ], q{Everything run in the right order};

  $Buddha::TestFixture::RECORDED = [];
  my $test2 = Test::FITesque::Test->new({
    data => [
      ['Buddha::TestFixture'],
      ['click here', qw(button search)],
      ['one', qw(two three)],
    ],
  });
  is $test2->test_count(), 5, q{Tests added from constructor};

  $test2->run_tests();
  is_deeply $Buddha::TestFixture::RECORDED, [
    [qw(CLICK_HERE button search)],
    [qw(ONE two three)],
  ], q{Everything run in right order};

}

Running_test_with_no_data: {
  my $test = Test::FITesque::Test->new();
  throws_ok {
    $test->run_tests();
  } qr{^Attempted to run empty test},
    q{Can't run empty tests};
  
}

Attempting_to_use_non_existant_fixture_class: {
  my $test = Test::FITesque::Test->new();

  $test->add('Class::That::Does::Not::Exist');
  throws_ok {
    $test->test_count();
  } qr{Could not load 'Class::That::Does::Not::Exist' fixture},
    q{Non existant fixture class (count)};
  throws_ok {
    $test->run_tests();
  } qr{Could not load 'Class::That::Does::Not::Exist' fixture},
    q{Non existant fixture class (run)};
}

Attempting_to_use_non_existant_method: {
  my $test = Test::FITesque::Test->new();
  $test->add('Buddha::TestFixture');
  $test->add('non existant method');
  
  throws_ok {
    $test->run_tests();
  } qr{Unable to run tests, no method available for action "non existant method"},
    q{run_tests bails early on unavailable method};
}

Fixture_class_is_not_a_FITesque_fixture: {
  my $test = Test::FITesque::Test->new();
  $test->add('Buddha::TestFixture2');
  $test->add('foo');

  throws_ok {
    $test->test_count();
  } qr{Fixture class 'Buddha::TestFixture2' is not a FITesque fixture},
    q{Class is not a FITesque fixture (count)};
  
  throws_ok {
    $test->run_tests();
  } qr{Fixture class 'Buddha::TestFixture2' is not a FITesque fixture},
    q{Class is not a FITesque fixture (run)};
}

Fixture_methods_called_on_object: {
  my $test = Test::FITesque::Test->new();
  $test->add('Buddha::TestFixture3', 'i am an object');
  $test->add('object method', 'hehe');
  
  $Buddha::TestFixture3::NEW = undef;
  $Buddha::TestFixture3::OBJ = undef;
 
  lives_ok {
    $test->run_tests();
  } q{Methods called on objects};

  is $Buddha::TestFixture3::NEW, q{I AM AN OBJECT}, q{Constructor passed arguments};
  is $Buddha::TestFixture3::OBJ, q{HEHE}, q{Method called on object};
}

Cannot_attempt_to_run_tests_twice: {
  my $test = Test::FITesque::Test->new();
  $test->add(q{Buddha::TestFixture});
  $test->add(q{apple});

  $test->run_tests();
  throws_ok {
    $test->run_tests();
  } qr{Attempted to run test more than once},
    q{Cannot run test twice};
}

Fixture_objects_destroyed_after_run_tests: {

  my $test = Test::FITesque::Test->new();
  $test->add(q{Buddha::DestroyFixture});
  $test->add(q{hehe});

  ok(!defined $Buddha::DestroyFixture::DESTROY_HAS_RUN, q{Object created});
  $test->run_tests();
  is($Buddha::DestroyFixture::DESTROY_HAS_RUN, 1, q{DESTROY has run});
}

Make_sure_runtime_methods_are_available: {

  my $test = Test::FITesque::Test->new();
  $test->add(q{Buddha::CheckFixture});
  $test->add(q{existing});
  $test->add(q{non existing});

  throws_ok {
    $test->run_tests();
  } qr{No method exists for 'non existing'},
    q{Methods are available at runtime};
}
