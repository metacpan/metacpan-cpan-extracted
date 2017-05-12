#!/usr/bin/env perl
# test facets on list elements


use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More;
use XML::LibXML;

BEGIN
 {  
     # old libxml2 versions break on regex 123\\s+(\\d+\\s)*456
     # there are so many bugs in old libxml2 releases!
     my $xml2_version = XML::LibXML::LIBXML_DOTTED_VERSION();
     $xml2_version lt '2.7'
         and plan skip_all => "Your libxml2 is too old (version $xml2_version)";

     plan tests => 60;
 }

set_compile_defaults
    elements_qualified => 'NONE'
  , sloppy_integers => 1;

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<simpleType name="t1">
  <list itemType="int" />
</simpleType>

<element name="test1">
  <simpleType>
    <restriction base="me:t1">
      <length value="2" />
    </restriction>
  </simpleType>
</element>

<!-- translated from example in xml-schema spec part 2 -->
<simpleType name="test2_t1">
  <list itemType="integer" />
</simpleType>
<simpleType name="test2_t2">
  <restriction base="me:test2_t1">
     <pattern value="123\\s+(\\d+\\s)*456"/>
  </restriction>
</simpleType>

<element name="test2" type="me:test2_t2" />

</schema>
__SCHEMA__

ok(defined $schema);

### test length

my $error = error_r($schema, test1 => <<_XML);
<test1>9 10 11</test1>
_XML
is($error, "list `9 10 11' does not have required length 2 at {http://test-types}test1#facet");

$error = error_r($schema, test1 => <<_XML);
<test1>12</test1>
_XML
is($error, "list `12' does not have required length 2 at {http://test-types}test1#facet");

$error = error_w($schema, test1 => [13]);
is($error, "list `13' does not have required length 2 at {http://test-types}test1#facet");

$error = error_w($schema, test1 => [14, 15, 16]);
is($error, "list `14 15 16' does not have required length 2 at {http://test-types}test1#facet");

test_rw($schema, test1 => <<_XML, [17, 18]);
<test1>17 18</test1>
_XML

### test patterns

test_rw($schema, test2 => <<_XML, [123, 456]);
<test2>123 456</test2>
_XML

test_rw($schema, test2 => <<_XML, [123, 987, 456]);
<test2>123 987 456</test2>
_XML

test_rw($schema, test2 => <<_XML, [123, 987, 567, 456]);
<test2>123 987 567 456</test2>
_XML

$error = error_r($schema, test2 => <<_XML);
<test2>999</test2>
_XML
is($error, "string `999' does not match pattern `123\\s+(\\d+\\s)*456' at {http://test-types}test2#facet");

$error = error_w($schema, test2 => [111, 999]);
is($error, "string `111 999' does not match pattern `123\\s+(\\d+\\s)*456' at {http://test-types}test2#facet");
