use strict;
use warnings;

use Test2::API qw(intercept);
use Test::More;
use Test::Routine::Util;

{
  package Abort::Test;
  sub throw {
    my $self = bless $_[1], $_[0];
    die $self;
  }

  sub as_test_abort_events {
    my @diag = @{ $_[0]{diagnostics} || [] };
    return [
      [ Ok => (pass => $_[0]{pass} || 0, name => $_[0]{description}) ],
      map {; [ Diag => (message => $_) ] } @diag,
    ];
  }
}

{
  package Abortive;
  use Test::Routine;

  use Test::More;

  use namespace::autoclean;

  test "this test will abort" => sub {
    my ($self) = @_;

    pass("one");
    pass("two");

    Abort::Test->throw({
      description => "just give up",
    });

    pass("three");
    pass("four");
    pass("five");
  };

  test "this will run just fine" => sub {
    pass("everything is just fine");
  };

  test "I like fine wines and cheeses" => sub {
    pass("wine wine wine wine cheese");

    Abort::Test->throw({
      pass => 1,
      description => "that was enough wine and cheese",
      diagnostics => [ "Fine wine", "Fine cheese" ],
    });

    fail("feeling gross");
  };
}

my $events = intercept {
  run_tests("test run with aborts", 'Abortive');
};

my @top = grep {; $_->isa('Test2::Event::Subtest') } @$events;
is(@top, 1, "we have only the one top-level subtest for Routine");

my @subtests = grep {; $_->isa('Test2::Event::Subtest') }
               @{ $top[0]->subevents };

is(@subtests, 3, "we ran three subtests (the three test methods)");

subtest "first subtest" => sub {
  my @oks = grep {; $_->isa('Test2::Event::Ok') } @{ $subtests[0]->subevents };
  is(@oks, 3, "three pass/fail events");
  ok($oks[0]->pass, "first passed");
  ok($oks[1]->pass, "second passed");
  ok(! $oks[2]->pass, "third failed");
  is($oks[2]->name, "just give up", "the final Ok test looks like our abort");
  isa_ok($oks[2]->get_meta('test_abort_object'), 'Abort::Test', 'test_abort_object');
};

subtest "third subtest" => sub {
  my @oks = grep {; $_->isa('Test2::Event::Ok') } @{ $subtests[2]->subevents };
  is(@oks, 2, "two pass/fail events");
  ok($oks[0]->pass, "first passed");
  ok($oks[1]->pass, "second passed");
  is(
    $oks[1]->name,
    "that was enough wine and cheese",
    "the final Ok test looks like our abort"
  );
  isa_ok($oks[1]->get_meta('test_abort_object'), 'Abort::Test', 'test_abort_object');

  my @diags = grep {; $_->isa('Test2::Event::Diag') } @{ $subtests[2]->subevents };
  is(@diags, 2, "we have two diagnostics");
  is_deeply(
    [ map {; $_->message } @diags ],
    [
      "Fine wine",
      "Fine cheese",
    ],
    "...which we expected",
  );
};


done_testing;
