#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 21;

BEGIN {
  use_ok "Test::FitNesse::Slim::StatementExecutor"
    or BAIL_OUT "Cannot use Test::FitNesse::Slim::StatementExecutor!";
}

my $single = Test::FitNesse::Slim::StatementExecutor->new;
$single->add_import("fitnesse.slim.test.library");
is($single->create("actor", "LibraryFixture", []), "OK", "create empty library actor");
is($single->create("library1", "EchoSupport", []), "OK", "create echo support library");
SKIP: {
  skip "actor fixture was not created", 3 unless $single->instance("actor");
  ok(!$single->instance("actor")->can("echo"), "actor leaves echo to library resolution");
  is($single->call("actor", "echo"), "null", "library echo returns the void result");
  is($single->call("actor", "echo_support_called"), "true", "echo support records its own call");
}

my $multiple = Test::FitNesse::Slim::StatementExecutor->new;
$multiple->add_import("fitnesse.slim.test.library");
is($multiple->create("actor", "LibraryFixture", []), "OK", "create empty actor for precedence case");
is($multiple->create("library1", "EchoSupport", []), "OK", "create earlier echo support library");
is($multiple->create("library2", "SpecialEchoSupport", []), "OK", "create later special echo support library");
is($multiple->call("actor", "echo_support_called"), "false", "earlier library begins uncalled");
is($multiple->call("actor", "special_echo_support_called"), "false", "later library begins uncalled");
is($multiple->call("actor", "echo"), "null", "shared method resolves to the later library");
is($multiple->call("actor", "echo_support_called"), "false", "earlier library did not receive the call");
is($multiple->call("actor", "special_echo_support_called"), "true", "later library recorded the call");

my $instances = Test::FitNesse::Slim::StatementExecutor->new;
$instances->add_import("fitnesse.slim.test.library");
is($instances->create("actor", "LibraryFixture", []), "OK", "create actor for instance-local state");
is($instances->create("library1", "EchoSupport", []), "OK", "create first echo support instance");
is($instances->create("library2", "EchoSupport", []), "OK", "create second echo support instance");
is($instances->call("library1", "echo_support_called"), "false", "first instance begins uncalled");
is($instances->call("actor", "echo"), "null", "actor dispatches echo to newest same-class library");
is($instances->call("library1", "echo_support_called"), "false", "call state remains local to the newest instance");
is($instances->call("library2", "echo_support_called"), "true", "newest instance records the call");
