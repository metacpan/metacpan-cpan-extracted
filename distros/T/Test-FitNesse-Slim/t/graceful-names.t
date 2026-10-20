#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 8;

BEGIN {
  use_ok "Test::FitNesse::Slim::StatementExecutor"
    or BAIL_OUT "Cannnot use Test::FitNesse::Slim::StatementExecutor!";

  use_ok "Test::FitNesse::Slim::Statement"
    or BAIL_OUT "Cannnot use Test::FitNesse::Slim::Statement!";
}

my $executor = Test::FitNesse::Slim::StatementExecutor::->new;

is_deeply(
  Test::FitNesse::Slim::Statement::->execute($executor, "i1", "import", "fitnesse.slim.test"),
  ["i1" => "OK"],
  "import test module"
);

is_deeply(
  Test::FitNesse::Slim::Statement->execute($executor, "m1", "make", "test_slim", "test slim with arguments", "nil"),
  ["m1" => "OK"],
  "make instance using graceful class name"
);

is(
  $executor->call("test_slim", "arg"),
  "nil",
  "call arg after graceful make"
);

is(
  $executor->call(
    "test_slim",
    "setArg",
    "<table><tr><td>name</td><td>bob</td></tr><tr><td>addr</td><td>here</td></tr></table>"
  ),
  "OK",
  "camelCase method setArg dispatches without exception"
);

is(
  $executor->call("test_slim", "name"),
  "bob",
  "name after setArg"
);

is(
  $executor->call("test_slim", "addr"),
  "here",
  "addr after setArg"
);
