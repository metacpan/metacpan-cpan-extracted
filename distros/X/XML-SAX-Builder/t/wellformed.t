# @(#) $Id: wellformed.t,v 1.1 2003/04/16 08:35:39 dom Exp $

# This set of tests is designed to check that well formed XML is always
# produced.  The section numbers correspond to the XML spec at
# <http://xml.com/axml/testaxml.htm>.  I've tried to do as much as I can
# here, but doubtless I've missed some bits.  Please supply patches for
# anything I've done wrong.  ;-)

use strict;
use warnings;

use Test::More 'no_plan';

use XML::SAX::Builder;
use XML::SAX::Writer;

my $xml_str;
my $x = XML::SAX::Builder->new(
    XML::SAX::Writer->new( Output => \$xml_str )
);

isa_ok( $x, 'XML::SAX::Builder' );

# §2.1
eval { $x->xml() };
like( $@, qr/one and only one root element allowed/, 'error when no elements' );
eval { $x->xml( $x->foo, $x->bar ) };
like( $@, qr/one and only one root element allowed/, 'error when many elements' );

# §2.3
eval { $x->xml( $x->XML ) };
like(
    $@,
    qr/names beginning with \/xml\/i are reserved/,
    'names beginning with XML are reserved',
);
eval { $x->xml( $x->Xml_User ) };
like(
    $@,
    qr/names beginning with \/xml\/i are reserved/,
    'names beginning with XML are reserved',
);

# There are a whole host of definitions in the spec.  I will come back
# to them when I figure out a nice regex for them...
my @bad_char_tests = (
    [ "invalid\033name", "bad char: ESC" ],
);

foreach ( @bad_char_tests ) {
    my ( $odd_name, $test_name ) = @$_;
    eval { $x->xml( $x->$odd_name ) };
    like( $@, qr/invalid character in name/, $test_name );
}

# §2.4  Character data is automatically taken care of by XML::SAX::Writer.

# §2.5  Nothing to do here.

# §2.6  Processing Instructions.  Similiar to XML element names.
eval { $x->xml( $x->xmlpi( xmlification => 'yup' ), $x->foo ) };
like(
    $@,
    qr/names beginning with \/xml\/i are reserved/,
    'PI targets beginning with XML are reserved',
);

# §2.7  Nothing to do here.

# §2.8  We don't generate a document prolog.  Dunno # whether we should, OTOH..

eval { $x->xml( $x->foo( $x->xmldtd( 'name', 'system', 'public' ) ) ) };
like(
    $@,
    qr/doctype must appear before the first element/,
    'doctype must appear before the first element (inside element)',
);

eval { $x->xml( $x->foo, $x->xmldtd( 'name', 'system', 'public' ) ) };
{ local $TODO = 'Not sure how to implement this one';
like(
    $@,
    qr/doctype must appear before the first element/,
    'doctype must appear before the first element (after root element)',
);
}

# This is really a validity constraint, but if we're generating a
# doctype, we should probably be enforcing it.
eval { $x->xml( $x->xmldtd( 'name', 'system', 'public' ), $x->foo ) };
{ local $TODO = 'Not sure how to implement';
like(
    $@,
    qr/doctype Name must match root element/,
    'doctype Name must match root element',
);
}

# §2.9  We don't generate a prolog, so we can't test for this.

# §2.12 B&D, that's us!
eval { $x->xml( $x->foo( { "xml:lang" => 'piffle' } ) ) };
like(
    $@,
    qr/invalid LanguageID/,
    'must supply a valid language tag to xml:lang',
) or diag $xml_str;

# §3 we automatically do the element type match in start/end tags.

# §3.1 Unique att spec.  We get these by virtue of passing in attributes
# in a hash.

# §3.1 No External Entity References.  I'm pretty sure that these are
# just disallowed because the data in an attribute is auto-escaped?
# Looks like it.

# §3.1 No < in Attribute Values.  Ditto.

# §4.1 Legal Character.  Shouldn't affect us because stuff gets auto
# escaped.

# §4.1 Entity Declared.  Ditto.
# §4.1 Parsed Entity.  Ditto.
# §4.1 No Recursion.  Ditto.
# §4.1 In DTD.  Ditto.

# vim: set ai et sw=4 syntax=perl :
