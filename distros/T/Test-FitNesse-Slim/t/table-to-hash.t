#! perl -T

use strict;
use utf8;
use warnings;

use Test::More;

use Test::FitNesse::Slim::StatementExecutor;

my @shouldNotChange = (
  [ "some string", "not a table" ],
  [ "<table>blah", "incomplete table" ],
  [ "<table><tr><td>hi</td></tr></table>", "too few columns" ],
  [ "<table><tr><td>hi</td><td>med</td><td>lo</td></tr></table>",
    "too many columns" ],
);

my @conversions = (
  [ "<table><tr><td>name</td><td>bob</td></tr></table>",
    { name => "bob" } ],
  [ " <table> <tr> <td> name </td> <td> bob </td> </tr> </table> ",
    { name => "bob"} ],
  [ "<table><tr><td>name</td><td>bob</td></tr><tr><td>addr</td><td>here</td></tr></table>",
    { name => 'bob', addr => 'here'} ],
);

sub shouldNotChange {
  my($string,$test_name) = @_;
  my $exec = Test::FitNesse::Slim::StatementExecutor->new;
  is($exec->replace_table_with_hash($string), $string, $test_name);
}

sub shouldChange {
  my($string,$expect) = @_;
  my $exec = Test::FitNesse::Slim::StatementExecutor->new;
  is_deeply($exec->replace_table_with_hash($string), $expect, "convert '$string'");
}

plan tests => @shouldNotChange + @conversions;
shouldNotChange @$_ for @shouldNotChange;
shouldChange    @$_ for @conversions;
