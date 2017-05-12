#!/usr/bin/env perl
# test facets on dates, shares some with numeric facets

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;
use XML::Compile::Util qw/pack_type/;

use Test::More tests => 9;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS"
        elementFormDefault="qualified">

<!-- Question by andrew campbell, 2013-02-08 -->
<element name="test1">
  <simpleType>
    <restriction base="dateTime">
      <minInclusive value="1995-01-01T00:00:00Z"/>
      <maxInclusive value="2120-12-31T00:00:00Z"/>
    </restriction>
  </simpleType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

set_compile_defaults
    include_namespaces    => 0
  , elements_qualified    => 'NONE'
  , use_default_namespace => 0;

test_rw($schema, test1 => '<test1>2012-01-01T00:00:00Z</test1>'
  , '2012-01-01T00:00:00Z');

