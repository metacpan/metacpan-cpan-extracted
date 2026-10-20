#! perl -T

use strict;
use warnings;

use lib "t/lib";

use File::Spec;
use Module::Build;
use Test::More tests => 9;

my $TEST_SLIM = "Fitnesse::Slim::Test::TestSlim";
my $TEST_SLIM_ARGS = $TEST_SLIM . "WithArguments";

BEGIN {
  use_ok("Test::FitNesse::Slim::StatementExecutor")
    || BAIL_OUT("Cannnot use Test::FitNesse::Slim::StatementExecutor!");

  use_ok("Test::FitNesse::Slim::Statement") || BAIL_OUT("Cannnot use Test::FitNesse::Slim::Statement!");
}

{
  my $caller = Test::FitNesse::Slim::StatementExecutor->new;

  my $response = $caller->create("x", $TEST_SLIM, []);
  is($response, "OK", "create an instance: $response ($@)");

  my $x = $caller->instance("x");
  is(ref($x), $TEST_SLIM);
}

{
  my $caller = Test::FitNesse::Slim::StatementExecutor->new;

  my $response = $caller->create("x", $TEST_SLIM_ARGS, [3]);
  is($response, "OK", "create an instance with arguments");

  my $x = $caller->instance("x");
  is($x->arg, 3);
}

{
  my $caller = Test::FitNesse::Slim::StatementExecutor->new;
  $caller->set_symbol("X", 3);

  my $response = $caller->create("x", $TEST_SLIM_ARGS, ['$X']);
  is($response, "OK", "create an instance with arguments that are symbols");

  my $x = $caller->instance("x");
  is($x->arg, 3);
}

{
  my $caller = Test::FitNesse::Slim::StatementExecutor->new;

  my $result = $caller->create("x", "TestModule::NoSuchClass", []);
  like($result, qr/\Q${Test::FitNesse::Slim::Statement::EXCEPTION_TAG}\Emessage:<<NO_CLASS TestModule::NoSuchClass\b/,
    "can't create an instance if there is no class:\n$result");
}
