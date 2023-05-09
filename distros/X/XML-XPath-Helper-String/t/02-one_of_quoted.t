#!perl
use 5.008;
use strict;
use warnings;
use Test::More tests => 9;

use XML::XPath::Helper::String qw(:all);


{
  is(one_of_quoted(["the value"], "foo"), "foo='the value'", "one_of_quoted - simple");
  is(one_of_quoted(["'a'", "b'''cd", "e"], "foo"),
     "foo=concat(\"'\",'a',\"'\") or foo=concat('b',\"'''\",'cd') or foo='e'",
     "one_of_quoted - complex");

  my $closure = one_of_quoted(["'a'", "b'''cd", "e"]);
  isa_ok($closure, 'CODE');
  is($closure->("FOO"),
     "FOO=concat(\"'\",'a',\"'\") or FOO=concat('b',\"'''\",'cd') or FOO='e'",
     "one_of_quoted closure 1");
  is($closure->("BAR"),
     "BAR=concat(\"'\",'a',\"'\") or BAR=concat('b',\"'''\",'cd') or BAR='e'",
     "one_of_quoted closure 2");
}

{
  is(not_one_of_quoted(["the value"], "foo"), "foo!='the value'", "not_one_of_quoted - simple");
  is(not_one_of_quoted(["'a'", "b'''cd", "e"], "foo"),
     "foo!=concat(\"'\",'a',\"'\") and foo!=concat('b',\"'''\",'cd') and foo!='e'",
     "not_one_of_quoted - complex");

  my $closure = not_one_of_quoted(["'a'", "b'''cd", "e"]);
  isa_ok($closure, 'CODE');
  is($closure->("FOO"),
     "FOO!=concat(\"'\",'a',\"'\") and FOO!=concat('b',\"'''\",'cd') and FOO!='e'",
     "not_one_of_quoted closure 1");
}

