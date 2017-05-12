#!/usr/bin/perl
# $Id: 10_with_xml.t 8 2008-10-22 07:16:55Z rjray $

# Test the usage of the XML tests as loaded via Test::Formats

use strict;
use warnings;

use File::Spec;
use XML::LibXML;
use Test::Builder::Tester tests => 6;

# Testing this:
use Test::Formats 'XML';

our(%schemas, %tests, $xmlcontent);

# By the time this test suite runs, all of the full range of cases for the
# Test::Formats::XML have been exercised by the tests specifically for that
# module. Here, we are only confirming that all of the exported functionality
# was correctly mapped by Test::Formats.

$schemas{dtd} = <<END_DTD_001;
<!ELEMENT data (#PCDATA)>
<!ELEMENT container (data+)>
END_DTD_001
$schemas{schema} = <<END_SCHEMA_001;
<?xml version="1.0"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    elementFormDefault="qualified" attributeFormDefault="unqualified">

    <xsd:element name="data" type="xsd:string" />

    <xsd:element name="container">
        <xsd:complexType>
            <xsd:sequence>
                <xsd:element maxOccurs="unbounded" minOccurs="1" ref="data" />
            </xsd:sequence>
        </xsd:complexType>
    </xsd:element>

</xsd:schema>
END_SCHEMA_001
$schemas{relaxng} = <<END_RELAXNG_001;
<?xml version="1.0"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
    <start>
        <choice>
            <ref name="container.elem" />
            <ref name="data.elem" />
        </choice>
    </start>
    <define name="data.elem">
        <element>
            <name ns="">data</name>
            <text />
        </element>
    </define>
    <define name="container.elem">
        <element>
            <name ns="">container</name>
            <oneOrMore>
                <ref name="data.elem" />
            </oneOrMore>
        </element>
    </define>
</grammar>
END_RELAXNG_001

$xmlcontent = <<END_XML;
<?xml version="1.0"?>
<container><data>foo</data></container>
END_XML

# Set up the tests to run. Rather than running them all at once (which would
# count as just one test to Test::Builder::Tester), do them one at a time, so
# it is clearer which routine fails.
%tests = (
    is_valid_against_sgmldtd   => [ \&is_valid_against_sgmldtd   => 'dtd' ],
    is_valid_against_dtd       => [ \&is_valid_against_dtd       => 'dtd' ],
    is_valid_against_xmlschema => [ \&is_valid_against_xmlschema => 'schema' ],
    is_valid_against_xsd       => [ \&is_valid_against_xsd       => 'schema' ],
    is_valid_against_relaxng   => [ \&is_valid_against_relaxng   => 'relaxng' ],
    is_valid_against_rng       => [ \&is_valid_against_rng       => 'relaxng' ],
);

for my $test (sort keys %tests)
{
    test_out("ok 1 - $test");
    $tests{$test}->[0]->($xmlcontent, $schemas{$tests{$test}->[1]}, $test);
    test_test("import of $test");
}

exit 0;
