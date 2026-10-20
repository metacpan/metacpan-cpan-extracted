#! perl -T

use strict;
use utf8;
use warnings;

my @tests;
BEGIN {
  @tests = (
    [ "serialize an empty list",
      [],
      "[000000:]",
    ],

    [ "serialize a one-item list",
      ["hello"],
      "[000001:000005:hello:]",
    ],

    [ "serialize a two-item list",
      [qw/ hello world /],
      "[000002:000005:hello:000005:world:]",
    ],

    [ "serialize a nested list",
      [["element"]],
      "[000001:000024:[000001:000007:element:]:]",
    ],

    [ "serialize a list with a non-string",
      [1],
      "[000001:000001:1:]",
    ],

    [ "serialize numeric zero without treating it as null",
      [0],
      "[000001:000001:0:]",
    ],

    [ "serialize an empty string as a zero-length item",
      [""],
      "[000001:000000::]",
    ],

    [ "serialize an undefined element",
      [undef],
      "[000001:000004:null:]",
    ],

    [ "serialize a string with multibyte chars",
      ["Köln"],
      "[000001:000004:K\303\266ln:]",
    ],

    [ "serialize a string with UTF8",
      ["Espa\303\261ol"],
      "[000001:000007:Espa\303\261ol:]",
    ],

    [ "serialize a supplementary Unicode character using UTF-16 code-unit length",
      ["\x{1F600}"],
      "[000001:000002:\x{1F600}:]",
    ],

    [ "serialize a string with a trailing newline",
      ["foo\n"],
      "[000001:000004:foo\n:]",
    ],
  );
}

use Test::More tests => @tests + 3;

BEGIN { use_ok("Test::FitNesse::Slim::List") || BAIL_OUT("Cannot use Test::FitNesse::Slim::List!") }

for (@tests) {
  use bytes;
  my($test_name,$input,$expected) = @$_;
  ok(Test::FitNesse::Slim::List->new($input)->serialize eq $expected, $test_name);
}

my $list = [
  "id",
  "ØÅÆ_ØÅÆ",
  "Æ_ØÅ",
];

my $wire = Test::FitNesse::Slim::List->new($list)->serialize;
my @round = Test::FitNesse::Slim::List->new($wire)->list;

is_deeply(\@round, $list, "round-trip UTF-8 strings in serialized list");

is(
  Test::FitNesse::Slim::List::->new([id1 => undef])->serialize,
  "[000002:000003:id1:000004:null:]",
  "undef serializes as slim null"
);
