#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 3;

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
  "import fitnesse.slim.test"
);
