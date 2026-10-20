#! perl -T

use strict;
use warnings;

use lib "t/lib";
use utf8;

my @cases;
BEGIN {
  @cases = (
    [ qw/ slim_to_perl_class   myPackage.MyClass        MyPackage::MyClass / ],
    [ qw/ slim_to_perl_class   this.that::theOther      This::That::TheOther / ],
    [ qw/ slim_to_perl_class   testModule.testSlim      TestModule::TestSlim / ],
    [ qw/ slim_to_perl_method  myMethod                 my_method / ],
    [ qw/ slim_to_perl_method  createTestSlimWithString create_test_slim_with_string / ],
  );
}

use Test::More tests => 8 + @cases;

my $have_test_exception;
BEGIN {
  use_ok("Test::FitNesse::Slim::StatementExecutor")
    || BAIL_OUT("Cannot use Test::FitNesse::Slim::StatementExecutor!");
  eval "use Test::Exception";
  $have_test_exception = $@ ? 0 : 1;
}

my $executor = Test::FitNesse::Slim::StatementExecutor->new;

is($executor->path_to_class("Foo::Bar::Baz"), "Foo/Bar/Baz.pm", "path_to_class");

SKIP: {
  skip "Text::Exception not installed", 1 unless $have_test_exception;

  throws_ok { $executor->require("Foo::Bar::Baz") }
    qr/message:<<COULD_NOT_INVOKE_CONSTRUCTOR Foo::Bar::Baz\b/,
    "require a class";
}

for (@cases) {
  my($method,$arg,$expected) = @$_;

  my $statement = Test::FitNesse::Slim::StatementExecutor->new;
  is($statement->$method($arg), $expected, "$arg -> $expected");
}

{
  my $ID = "test_slim";
  my $executor = Test::FitNesse::Slim::StatementExecutor::->new;
  $executor->add_import("fitnesse.slim.test");

  is $executor->create($ID, "TestSlim", []),
    "OK",
    "create test_slim";

  my $returned = $executor->call($ID, "createTestSlimWithString", "Uncle");

  my $SYM = "TESTñSLIMØINSTÆNCEÅ";
  $executor->set_symbol($SYM, $returned);

  my $stored = $executor->get_symbol($SYM);

  ok ref $stored, "stored symbol is a reference";
  ok $stored == $returned, "stored symbol is the same instance";

  my @args = $executor->replace_symbols('$' . $SYM);
  ok ref($args[0]), "exact symbol substitution returns a reference";
  ok $args[0] == $returned, "exact symbol substitution preserves identity";
}
