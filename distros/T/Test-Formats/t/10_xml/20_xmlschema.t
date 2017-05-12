#!/usr/bin/perl
# $Id: 20_xmlschema.t 8 2008-10-22 07:16:55Z rjray $

# Exercise the XML Schema tests

use strict;
use warnings;
use vars qw($dir);

use File::Spec;
use XML::LibXML;
use Test::Builder::Tester tests => 3;

# Testing this:
use Test::Formats::XML;

# $dir gets used with File::Spec->catfile() to get O/S-agnostic paths to the
# files used by the tests.
$dir = (File::Spec->splitpath(File::Spec->rel2abs($0)))[1];

# Used and re-used
our($schema, $xmlcontent);

# Start with some simple static-string content
$schema = <<END_SCHEMA_001;
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

test_out("ok 1 - string+string");
test_out("not ok 2 - string+string fail");
test_out("ok 3 - string+string nested content");
is_valid_against_xmlschema(q{<?xml version="1.0"?>
<data>foo</data>
}, $schema, "string+string");
is_valid_against_xmlschema(q{<?xml version="1.0"?>
<container></container>
}, $schema, "string+string fail");
is_valid_against_xmlschema(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $schema, "string+string nested content");
test_test(name => 'basic string+string arguments', skip_err => 1);

test_out("ok 1 - is_valid_against_xsd alias");
is_valid_against_xsd(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $schema, "is_valid_against_xsd alias");
test_test(name => 'string+string arguments, is_valid_against_xsd alias',
          skip_err => 1);

test_out("ok 1 - xmlschema_ok alias");
xmlschema_ok(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, $schema, "xmlschema_ok alias");
test_test(name => 'string+string arguments, xmlschema_ok alias', skip_err => 1);

exit 0;
