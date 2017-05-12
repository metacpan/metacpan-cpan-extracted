#!/usr/bin/env perl
# patterns are still poorly supported.

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 18;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1">
  <simpleType>
    <restriction base="string">
      <pattern value="a.c" />
    </restriction>
  </simpleType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);
my $error;

test_rw($schema, "test1" => <<__XML, "abc");
<test1>abc</test1>
__XML

$error = error_r($schema, test1 => <<__XML);
<test1>abbc</test1>
__XML
is($error, "string `abbc' does not match pattern `a.c' at {http://test-types}test1#facet");

$error = error_w($schema, test1 => 'abbc');
is($error, "string `abbc' does not match pattern `a.c' at {http://test-types}test1#facet");
