#!/usr/bin/env perl
# test facets on duration, shares some with numeric facets

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;
use XML::Compile::Util qw/pack_type/;

use Test::More tests => 21;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS"
        elementFormDefault="qualified">

<!-- Question by Anthony Yen, 2016-01-14 -->
<element name="test1">
  <simpleType>
    <restriction base="duration">
      <minInclusive value="P1970Y01M01D"/>
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

# a bit more
test_rw($schema, test1 => '<test1>P1970Y02M01D</test1>'
  , 'P1970Y02M01D');

# a bit less
my $error = error_r($schema, test1 => '<test1>P1970Y</test1>');
is($error, "too small minInclusive duration P1970Y, min P1970Y01M01D at {http://test-types}test1#facet");

# exact
test_rw($schema, test1 => '<test1>P1970Y01M01D</test1>'
  , 'P1970Y01M01D');

