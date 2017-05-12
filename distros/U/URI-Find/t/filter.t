#!/usr/bin/perl -w

# Test the filter function

use strict;

use Test::More 'no_plan';

use URI::Find;


my @tasks = (
  ["Foo&Bar http://abc.com.", "Foo&amp;Bar xx&."],
  ["http://abc.com. http://abc.com.", "xx&. xx&."],
  ["http://abc.com?foo=bar&baz=foo", "xx&"],
  ["& http://abc.com?foo=bar&baz=foo", "&amp; xx&"],
  ["http://abc.com?foo=bar&baz=foo &", "xx& &amp;"],
  ["Foo&Bar http://abc.com", "Foo&amp;Bar xx&"],
  ["http://abc.com. Foo&Bar", "xx&. Foo&amp;Bar"],
  ["Foo&Bar http://abc.com. Foo&Bar", "Foo&amp;Bar xx&. Foo&amp;Bar"],
  ["Foo&Bar\nhttp://abc.com.\nFoo&Bar", "Foo&amp;Bar\nxx&.\nFoo&amp;Bar"],
  ["Foo&Bar\nhttp://abc.com. http://def.com.\nFoo&Bar", 
   "Foo&amp;Bar\nxx&. xx&.\nFoo&amp;Bar"],

  # Thing which looks like a URL but isn't
  ["noturi:& should also be escaped", "noturi:&amp; should also be escaped"],

  # Thing which looks like a URL inside brackets, but isn't
  ["Something & <foo://bar&.com> whatever", "Something &amp; <foo://bar&amp;.com> whatever"],

  # Non-URL nested inside brackets
  [q{<a href="foo://example&.com">}, q{<a href="foo://example&amp;.com">}],
);

for my $task (@tasks) {
    my($str, $result) = @$task;
    my $org = $str;
    my $f = URI::Find->new(sub { return "xx&" });
    $f->find(\$str, \&simple_escape);
    is($str, $result, "escape $org");
}

sub simple_escape {
    my($toencode) = @_;
    $toencode =~ s{&}{&amp;}gso;
    return $toencode;
}
