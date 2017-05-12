use Test::More;
use strict;
BEGIN { plan tests => 6 };
use XML::CommonNS qw(SVG XHTML2 RNG);
ok(1);

is( $RNG,    "http://relaxng.org/ns/structure/1.0" );
is( $SVG,    "http://www.w3.org/2000/svg" );
is( $XHTML2, "http://www.w3.org/2002/06/xhtml2" );

is( $SVG->extensionsDef, "{http://www.w3.org/2000/svg}extensionsDef" );

is(XML::CommonNS->uri('FOAF'), 'http://xmlns.com/foaf/0.1/');