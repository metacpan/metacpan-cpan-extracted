#!perl
use 5.008;
use strict;
use warnings;
use Test::More tests => 4;

use XML::XPath::Helper::String qw(:all);


{
  is(one_of_quoted("foo", "the value"), "foo='the value'", "one_of_quoted - simple");
  is(one_of_quoted("foo", "'a'", "b'''cd", "e"),
     "foo=concat(\"'\",'a',\"'\") or foo=concat('b',\"'''\",'cd') or foo='e'",
     "one_of_quoted - complex");
}

{
  is(not_one_of_quoted("foo", "the value"), "foo!='the value'", "not_one_of_quoted - simple");
  is(not_one_of_quoted("foo", "'a'", "b'''cd", "e"),
     "foo!=concat(\"'\",'a',\"'\") and foo!=concat('b',\"'''\",'cd') and foo!='e'",
     "not_one_of_quoted - complex");
}

