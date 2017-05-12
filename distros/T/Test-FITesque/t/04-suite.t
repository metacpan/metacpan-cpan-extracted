#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

BEGIN {
  use_ok 'Test::FITesque::Suite';
}
can_ok 'Test::FITesque::Suite', qw(new test_count run_tests add);

use Test::FITesque::Test;
use lib 't/lib';

use lib 't/mock';
use Test::FakeBuilder;
local $Test::FITesque::Suite::TEST_BUILDER = Test::FakeBuilder->new();
local $Test::FITesque::Test::TEST_BUILDER = Test::FakeBuilder->new();

Basic_usage: {
  my $suite = Test::FITesque::Suite->new();
  isa_ok $suite, q{Test::FITesque::Suite};

  my $test = Test::FITesque::Test->new();
  $test->add('Buddha::SuiteFixture');
  $test->add('foo');
  $test->add('bar');

  my $test2 = Test::FITesque::Test->new();
  $test2->add('Buddha::SuiteFixture');
  $test2->add('baz');

  $suite->add($test);
  $suite->add($test2);

  is $suite->test_count, 6, q{Suite has correct test count};
  $suite->run_tests();

  is_deeply $Buddha::SuiteFixture::RECORDED, [qw(foo bar baz)], q{Tests all run in correct order};
}

Test_is_not_a_FITesque_test: {
  my $suite = Test::FITesque::Suite->new();
  
  { 
    package Buddha::SuiteBadTest; 
    sub new { return bless {}, $_[0] }; 
    1; 
  }
  my $test = Buddha::SuiteBadTest->new();
  
  throws_ok{
    $suite->add($test);
  } qr/Attempted to add a test that was not a FITesque test/,
    q{Non FITesque test};
}

Suite_within_suite: {
  $Buddha::SuiteFixture::RECORDED = [];
  my $outer_suite = Test::FITesque::Suite->new();
  
  my $inner_suite = Test::FITesque::Suite->new();
  {
    my $test1 = Test::FITesque::Test->new();
    $test1->add('Buddha::SuiteFixture');
    $test1->add('foo');

    my $test2 = Test::FITesque::Test->new();
    $test2->add('Buddha::SuiteFixture');
    $test2->add('bar');

    $inner_suite->add($test1, $test2);
    is $inner_suite->test_count(), 3, q{Inner test_count correct};
  }
  
  
  my $test3 = Test::FITesque::Test->new();
  $test3->add('Buddha::SuiteFixture');
  $test3->add('baz');
  
  $outer_suite->add($inner_suite);
  is $outer_suite->test_count(), 3, q{Outer reflects inner count};
  
  $outer_suite->add($test3);
  is $outer_suite->test_count(), 6, q{Outer total count correct};

  $outer_suite->run_tests();
  is_deeply $Buddha::SuiteFixture::RECORDED, [qw(foo bar baz)], q{Everything ran in order};
}

Tests_added_at_constructor: {
  my $test = Test::FITesque::Test->new({
      data => [
        ['Buddha::SuiteFixture'],
        ['bar']
      ],
  });

  my $suite = Test::FITesque::Suite->new({ data => [$test] });
  is $suite->test_count(), 2, q{Correct count for tests at constructor};
}

Attempt_to_run_empty_suite: {
  my $suite = Test::FITesque::Suite->new();
  throws_ok {
    $suite->run_tests();
  } qr{Attempting to run a suite with no tests},
    q{Catch empty suite run};
}

Suite_with_no_test_methods: {
  my $test = Test::FITesque::Test->new();
  $test->add('Buddha::SuiteFixture');
  $test->add('not_a_test');

  my $suite = Test::FITesque::Suite->new();
  $suite->add($test);

  $Buddha::SuiteFixture::NOT_A_TEST_RUN = 0;
  is $suite->test_count(), 0, q{Correct test count};
  $suite->run_tests();
  ok $Buddha::SuiteFixture::NOT_A_TEST_RUN, q{Handle no test methods};
}
