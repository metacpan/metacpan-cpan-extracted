#! perl -T

use strict;
use utf8;
use warnings;

use Encode qw/ decode is_utf8 /;

use Test::More tests => 17;

my $have_test_exception;
BEGIN {
  use_ok("Test::FitNesse::Slim::List") || BAIL_OUT("Cannot use Test::FitNesse::Slim::List!");
  eval "use Test::Exception";
  $have_test_exception = $@ ? 0 : 1;
}

SKIP: {
  skip "Test::Exception not installed", 5 unless $have_test_exception;

  throws_ok { Test::FitNesse::Slim::List->new(undef)->list }
    qr/cannot deserialize undefined value/, "can't deserialize undefined value";

  throws_ok { Test::FitNesse::Slim::List->new("")->list }
    qr/cannot deserialize empty string/, "can't deserialize empty string";

  throws_ok { Test::FitNesse::Slim::List->new("hello")->list }
    qr/syntax error\b.*missing open bracket/,
    "can't deserialize string that doesn't start with an open bracket";

  throws_ok { Test::FitNesse::Slim::List->new("[000000:")->list }
    qr/syntax error\b.*missing close bracket/,
    "can't deserialize string that doesn't end with a bracket";

  throws_ok { Test::FitNesse::Slim::List->new(<<EOF)->list }
[000002:000119:[000006:000015:scriptTable_3_0:000004:call:000016:scriptTableActor:000005:setTo:000015:System\\Language:000007:Espa\361ol:]:000033:[000002:000005:hello:000003:bob:]:]
EOF
    qr/cannot deserialize non-UTF-8 encoding/,
    "bad Unicode character";
}

sub check_round_trip {
  my($l,$name) = @_;
  @$l = map is_utf8($_) ? $_ : decode("UTF-8", $_, 1), @$l;
  my $serialized = Test::FitNesse::Slim::List->new($l)->serialize;
  my $deserialized = [ Test::FitNesse::Slim::List->new($serialized)->list ];
  is_deeply $deserialized, $l, $name;
}

check_round_trip [], "empty list";

check_round_trip ["hello"], "one-element list";

check_round_trip [qw/ hello bob /], "two-element list";

check_round_trip ["hello", [qw/ bob micah /], "today"], "sublists";

check_round_trip ["Köln"], "deserialize list with multibyte char";

check_round_trip ["Kö"],
  "deserialize list with string that ends with multibyte char";

check_round_trip ["123456789012345", "Espa\303\261ol"],
  "deserialize list with UTF-8";

my $raw = "000305:[000003:000085:[000004:000015:scriptTable_0_0:000004:make:000016:scriptTableActor:000009:MyFixture:]:000091:[000005:000015:scriptTable_0_1:000004:call:000016:scriptTableActor:000003:foo:000004:K\303\266ln:]:000094:[000005:000015:scriptTable_0_2:000004:call:000016:scriptTableActor:000003:bar:000007:Espa\303\261ol:]:]";

# good news: the length prefix is the number of bytes
# in the UTF-8 encoded list, not the number of characters
# as with list elements
is length($raw), 6 + 1 + 305;

my $lst = [ Test::FitNesse::Slim::List->new(substr $raw, 7)->list ];
my $expect = [
  [ qw/ scriptTable_0_0 make scriptTableActor MyFixture / ],
  [ qw/ scriptTable_0_1 call scriptTableActor foo Köln / ],
  [ qw/ scriptTable_0_2 call scriptTableActor bar Español / ],
];

is_deeply $lst, $expect, "actual list transmitted by fitnesse";

my $nested_statement =
  "[000006:000048:scriptTable_42_0/scriptTable_2_0/scriptTable_1_1:" .
  "000013:callAndAssign:000007:CONTENT:000016:scriptTableActor:" .
  "000004:echo:000000::]";
my $decoded_statement = eval {
  [ Test::FitNesse::Slim::List->new($nested_statement)->list ]
};
is_deeply $decoded_statement,
  [ "scriptTable_42_0/scriptTable_2_0/scriptTable_1_1",
    "callAndAssign", "CONTENT", "scriptTableActor", "echo", "" ],
  "deserialize nested script-table statement with empty argument";

my $long_value = 'x' x 1_000_000;
my $long_wire = '[000001:1000000:' . $long_value . ':]';
my @long_list = Test::FitNesse::Slim::List->new($long_wire)->list;
is_deeply \@long_list, [$long_value],
  'deserialize v0.4 list string with a length wider than six digits';
