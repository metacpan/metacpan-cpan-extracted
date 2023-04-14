use strict;
use warnings;

use Test2::API qw(intercept);
use Test::More;
use Test::Routine::Util;

{
  package ThisFails;
  use Test::Routine;

  use Test::More;

  test "this test will pass" => sub {
    pass("one");
    pass("two");
    pass("three");
  };

  test "this test will fail" => sub {
    pass("one");
    fail("two");
    pass("three");
  };

  around run_test => sub {
    my ($orig, $self, @rest) = @_;
    my $rc = $self->$orig(@rest);
    diag $rc ? "pass-result" : "fail-result";
  };
}

my $events = intercept {
  run_tests("test run with aborts", 'ThisFails');
};

my @top = grep {; $_->isa('Test2::Event::Subtest') } @$events;
is(@top, 1, "we have one top-level subtest for Routine");

my @subtests = grep {; $_->isa('Test2::Event::Subtest') }
               @{ $top[0]->subevents };

is(@subtests, 2, "we ran two subtests (the two test methods)");

subtest "first subtest" => sub {
  my @subevents = @{ $subtests[0]->subevents };

  my @oks = grep {; $_->isa('Test2::Event::Ok') } @subevents;
  is(@oks, 3, "three pass/fail events");

  ok($oks[0]->pass, "assertion passed");
  is($oks[0]->name, "one", "correct name");

  ok($oks[1]->pass, "assertion passed");
  is($oks[1]->name, "two", "correct name");

  ok($oks[2]->pass, "assertion passed");
  is($oks[2]->name, "three", "correct name");
};

subtest "second subtest" => sub {
  my @subevents = @{ $subtests[1]->subevents };

  my @oks = grep {; $_->isa('Test2::Event::Ok') } @subevents;
  is(@oks, 3, "three pass/fail events");

  ok($oks[0]->pass, "assertion passed");
  is($oks[0]->name, "one", "correct name");

  ok(!$oks[1]->pass, "assertion failed");
  is($oks[1]->name, "two", "correct name");

  ok($oks[2]->pass, "assertion passed");
  is($oks[2]->name, "three", "correct name");
};

{

  my @diags = grep {; $_->isa('Test2::Event::Diag') } @{ $top[0]->subevents };

  is(
    (grep {; $_->message eq 'pass-result' } @diags),
    1,
    "we got one pass-result",
  );

  is(
    (grep {; $_->message eq 'fail-result' } @diags),
    1,
    "we got one fail-result",
  );
};

done_testing;
__END__
