#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Builder::Tester;
use Test::XML::Easy;
use XML::Easy::Text qw(xml10_write_document);

########################################################################
# doesn't show anything extra when we suceeed

test_out("ok 1 - xml test");
is_xml("<foo/>","<foo/>",{ show_xml => 1});
test_test("nothing when doesn't fail is_xml");

test_out("ok 1 - not xml test");
isnt_xml("<foo/>","<bar/>",{ show_xml => 1});
test_test("nothing when doesn't fail isnt_xml");

########################################################################
# shows the got xml when we fail

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("Element '/foo[1]' does not match '/bar[1]'");
test_diag("The XML that we expected was:");
test_diag("<bar/>");
test_diag("The XML that we received was:");
test_diag("<foo></foo>");
is_xml("<foo></foo>","<bar/>",{ show_xml => 1});
test_test("is_xml diagnostics");

test_out("not ok 1 - not xml test");
test_fail(+4);
test_diag("Unexpectedly matched the XML we didn't expect");
test_diag("The XML that we received was:");
test_diag("<wibble   />");
isnt_xml("<wibble   />","<wibble />",{ show_xml => 1});
test_test("isnt_xml diagnostics");

########################################################################
# show the got xml when we fail even if we handed in objects

my $foo = XML::Easy::Element->new("foo", {}, ['']);
my $bar = XML::Easy::Element->new("bar", {}, ['']);

my @foo_str = split /\n/, xml10_write_document($foo);
my @bar_str = split /\n/, xml10_write_document($bar);

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("Element '/foo[1]' does not match '/bar[1]'");
test_diag("The XML that we expected was:");
test_diag($_) foreach @bar_str;
test_diag("The XML that we received was:");
test_diag($_) foreach @foo_str;
is_xml($foo,$bar,{ show_xml => 1});
test_test("is_xml diagnostics with objects");

test_out("not ok 1 - not xml test");
test_fail(+4);
test_diag("Unexpectedly matched the XML we didn't expect");
test_diag("The XML that we received was:");
test_diag($_) foreach @foo_str;
isnt_xml($foo,"<foo    />",{ show_xml => 1});
test_test("isnt_xml diagnostics with objects");
