#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 15;

use XML::SAX::Builder;
use XML::SAX::Writer;

my $xml_str;
my $w = XML::SAX::Writer->new( Output => \$xml_str );
my $xb = XML::SAX::Builder->new( $w );

isa_ok( $xb, 'XML::SAX::Builder' );
can_ok( $xb, qw( xml xmlns ) );

my $tag = $xb->foo( 'bar' );
isa_ok( $tag, 'XML::SAX::Builder::Tag' );

$xb->xml( $tag );
is( $xml_str, '<foo>bar</foo>', 'got some xml back' )
    or diag $xml_str;

$xb->xml(
    $xb->foo( $xb->first_tag( '1' ), 'In Between', $xb->second_tag( '2' ) ) );
is( $xml_str,
    '<foo><first_tag>1</first_tag>In Between<second_tag>2</second_tag></foo>',
    'got some xml back with nested tags' )
        or diag $xml_str;

$xb->xml( $xb->foo( { attr => 'val' }, 'bar' ) );
is( $xml_str, "<foo attr='val'>bar</foo>",
    'got some xml back with attributes' );

$xb->xml( $xb->xmlns( '' => 'urn:foo', $xb->foo() ) );
is( $xml_str, "<foo xmlns='urn:foo' />", 'got xml with default namespace' );

$xb->xml(
    $xb->xmlns( '' => 'urn:foo', $xb->xmlns( bar => 'urn:bar', $xb->foo() ) ) );
is(
    $xml_str,
    "<foo xmlns='urn:foo' xmlns:bar='urn:bar' />",
    'got xml with multiple namespace'
);

{
    local $TODO = 'Pending bugfix in XML::Filter::BufferText';
    $xb->xml( $xb->foo( $xb->xmlcdata( '<dodgy>&<text>' ) ) );
    is( $xml_str, "<foo><![CDATA[<dodgy>&<text>]]></foo>", 'got xml with cdata' );
}

{
    my $prefix_el = 'pfx:foo';
    $xb->xml( $xb->xmlns( pfx => 'urn:my-prefix', $xb->$prefix_el( 'bar') ) );
    is( $xml_str, "<pfx:foo xmlns:pfx='urn:my-prefix'>bar</pfx:foo>",
        'got xml with prefixed element name' );
}

# More prefix tests.  Use the new way...
{
    my $pfx = $xb->xmlprefix( 'xxx' );
    $xb->xml( $pfx->xmlns( xxx => 'urn:xxx', $pfx->foo() ) );
    is( $xml_str, "<xxx:foo xmlns:xxx='urn:xxx' />",
        'got xml using prefix generator' );
}

$xb->xml(
    $xb->xmldtd(
        'html',
        '-//W3C//DTD XHTML 1.0 Strict//EN',
        'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'
    ),
    $xb->html( $xb->head( $xb->title ), $xb->body, ),
);
is(
    $xml_str,
"<!DOCTYPE html PUBLIC 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd' '-//W3C//DTD XHTML 1.0 Strict//EN' ><html><head><title /></head><body /></html>",
    'got xml with doctype'
);

$xb->xml(
    $xb->xmlcomment( 'hello world' ),
    $xb->foo(),
);
is( $xml_str, '<!--hello world--><foo />', 'xmlcomment()' );

$xb->xml(
    $xb->xmlpi( stylesheet => 'nope' ),
    $xb->foo(),
);
is( $xml_str, '<?stylesheet nope?><foo />', 'xmlpi()' );

$xb->xml(
    $xb->xmlns(
        '' => 'http://www.w3.org/1999/xhtml', 
        $xb->html(
            $xb->head(
                $xb->title( 'The Title' ),
                $xb->meta( { name => 'generator', content => 'XML::SAX::Builder' } ),
            ),
            $xb->body(
                $xb->h1( 'Heading' ),
                $xb->p( 'Paragraph & Stuff <...>' ),
                $xb->ul(
                    $xb->li( 'List Item' ),
                    $xb->li( 'Another List Item' ),
                ),
            ),
        ),
    ),
);
is( $xml_str, "<html xmlns='http://www.w3.org/1999/xhtml'><head><title>The Title</title><meta content='XML::SAX::Builder' name='generator' /></head><body><h1>Heading</h1><p>Paragraph &amp; Stuff &lt;...&gt;</p><ul><li>List Item</li><li>Another List Item</li></ul></body></html>", 'complex xhtml example' );

# vim: set ai et sw=4 syntax=perl :
