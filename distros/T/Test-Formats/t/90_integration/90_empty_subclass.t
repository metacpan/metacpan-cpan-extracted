#!/usr/bin/perl
# $Id: 90_empty_subclass.t 8 2008-10-22 07:16:55Z rjray $

# Test the usage of the XML tests as loaded via Test::Formats

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use File::Spec;
use XML::LibXML;
use Test::Builder::Tester tests => 6;

# This is what is being tested. It relies on FindBin correctly identifying the
# location of this test-script. Note that the "specialization" is given as a
# full package name, since we don't want to try to load MyTestFormats::XML.
use MyTestFormats 'Test::Formats::XML';

our(%schemas, %tests, $xmlcontent);

# This is largely the same set of tests as are used for 10_with_xml.t. The
# point here is just to determine that an empty sub-class of Test::Formats
# works as well as the "real thing".

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
