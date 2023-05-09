#!perl
use 5.008;
use strict;
use warnings;
use Test::More tests => 11;

use XML::XPath::Helper::String qw(quoted_string);

{
  # Empty input.
  is(quoted_string(undef), "''", "Argument is undef");
  is(quoted_string(""),    "''", "Argument is empty string");

  is_deeply(quoted_string([]),    [],    "empty array");
  is_deeply(quoted_string([""]), ["''"], "array with one empty string");
}


{
  is(quoted_string("foo bar "), "'foo bar '",   "Argument without single quote");
  is(quoted_string("''foo' '"),
     "concat(\"''\",'foo',\"'\",' ',\"'\")", "Argument with single quotes");

  is_deeply(quoted_string(["x'y", "123"]),
            ["concat('x',\"'\",'y')", "'123'"], "Argument is two-element array");
}


{
  # Error cases.
  eval {quoted_string({})};
  ok($@, "Exception has been thrown");
  like($@, qr/^Argument must be a string or a reference to an array\b/, "Message as expected.");

  eval {quoted_string()};
  ok($@, "Exception has been thrown");
  like($@, qr/^Wrong number of arguments\b/, "Message as expected.");

}


