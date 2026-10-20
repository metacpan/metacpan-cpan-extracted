#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 7;

BEGIN {
  use_ok "Test::FitNesse::Slim::StatementExecutor"
    or BAIL_OUT "Cannot use Test::FitNesse::Slim::StatementExecutor!";
}

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->add_import("fitnesse.fixtures");

is($executor->create("setup", "SetUp", []), "OK", "create SetUp fixture");
is($executor->call("setup", "table", []), "null", "accept empty SetUp table hook");
like($executor->call("setup", "table", ["unexpected"]),
   qr/__EXCEPTION__:message:<<SetUp table hook expects no rows at .*SetUp\.pm line \d+\.>>/,
   "reject nonempty SetUp table hook");
is($executor->create("teardown", "TearDown", []), "OK", "create TearDown fixture");
is($executor->call("teardown", "table", []), "null", "accept empty TearDown table hook");
like($executor->call("teardown", "table", ["unexpected"]),
   qr/__EXCEPTION__:message:<<TearDown table hook expects no rows at .*TearDown\.pm line \d+\.>>/,
   "reject nonempty TearDown table hook");
