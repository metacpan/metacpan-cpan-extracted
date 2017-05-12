#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

BEGIN { use_ok 'Test::XPath' or die; }

my $xml = <<'XML';
<html>
  <body>foo</body>
</html>
XML

package Test::XPath::Subclass;

use base 'Test::XPath';

package main;

my $sub = Test::XPath::Subclass->new(xml => $xml);
isa_ok $sub, 'Test::XPath::Subclass';
