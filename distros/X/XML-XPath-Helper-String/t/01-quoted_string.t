#!perl
use 5.008;
use strict;
use warnings;
use Test::More tests => 7;

use XML::XPath::Helper::String qw(quoted_string);

{
  # Empty input.
  is(quoted_string(),      "''", "No argument");
  is(quoted_string(undef), "''", "Argument is undef");
  is(quoted_string(""),    "''", "Argument is empty string");
}

{
  is(quoted_string("foo bar "), "'foo bar '",   "Argument without single quote");
  is(quoted_string("''foo' '"),
     "concat(\"''\",'foo',\"'\",' ',\"'\")", "Argument with single quotes");
}


{
  eval {quoted_string([])};
  ok($@, "Exception has been thrown");
  like($@, qr/^Argument must be a scalar\b/, "Message as expected.");
}


