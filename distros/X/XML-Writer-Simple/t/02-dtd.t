#!/usr/bin/perl 

use Test::More tests => 2;
use XML::Writer::Simple dtd => "t/02-dtd.dtd";

is(xx(), "<xx/>");
is(xx(yy("foo")), "<xx><yy>foo</yy></xx>");
