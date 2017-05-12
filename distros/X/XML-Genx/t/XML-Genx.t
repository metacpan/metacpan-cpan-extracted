#!/usr/bin/perl -w
# @(#) $Id: XML-Genx.t 1266 2006-10-08 16:26:55Z dom $

use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::More tests => 115;

BEGIN {
    use_ok( 'XML::Genx' );
    use_ok(
        'XML::Genx::Constants', qw(
            GENX_SUCCESS
            GENX_SEQUENCE_ERROR
            GENX_BAD_NAME
            GENX_NON_XML_CHARACTER
            )
    );
}

my $w = XML::Genx->new();
isa_ok( $w, 'XML::Genx' );
can_ok( $w, qw(
    GetVersion
    StartDocFile
    StartDocSender
    LastErrorMessage
    LastErrorCode
    GetErrorMessage
    StartElementLiteral
    AddAttributeLiteral
    EndElement
    EndDocument
    Comment
    PI
    DeclareNamespace
    DeclareElement
    DeclareAttribute
) );

# Subtly different to VERSION()...
is( XML::Genx->GetVersion, 'beta5', 'GetVersion()' );

is(
    test_basics(),
    '<!--hello world-->
<?ping pong?>
<g1:foo xmlns:g1="urn:foo" g1:baz="quux">bar!</g1:foo>',
    'test_basics() output'
);

is(
    test_empty_namespace(),
    '<foo bar="baz"></foo>',
    'test_empty_namespace() output',
);

is(
    test_undef_namespace(),
    '<foo bar="baz"></foo>',
    'test_undef_namespace() output',
);

is(
    test_no_namespace(),
    '<foo bar="baz"></foo>',
    'test_no_namespace() output',
);

test_bad_filehandle();
test_declare_namespace();
test_declare_element();
test_declare_attribute();

is(
    test_declared_in_use(),
    '<foo:bar xmlns:foo="urn:foo" foo:baz="quux"></foo:bar>',
    'test_declared_in_use() output',
);

is(
    test_declared_no_namespace(),
    '<bar baz="quux"></bar>',
    'test_declared_no_namespace() output',
);

is(
    test_declared_with_namespace(),
    '<el xmlns="http://example.com/#ns" xmlns:g1="http://example.com/#ns2" g1:at="val"></el>',
    'test_declared_with_namespace() output',
);

is(
    test_sender(),
    "<foo>\x{0100}dam</foo>",
    'test_sender() output',
);

is(
    test_astral(),
    "<monogram-for-earth>\x{1D300}</monogram-for-earth>",
    'test_astral() output',
);

is(
    test_declared_namespace_in_literal(),
    '<x:foo xmlns:x="urn:foo" x:attr=""></x:foo>',
    'test_declared_namespace_in_literal() output',
);

# One of the examples from the XML canonicalization spec.
is(
    test_c14n_example_3_3(),
    q{<doc>
   <e1></e1>
   <e2></e2>
   <e3 id="elem3" name="elem3"></e3>
   <e4 id="elem4" name="elem4"></e4>
   <e5 xmlns="http://example.org" xmlns:a="http://www.w3.org" xmlns:b="http://www.ietf.org" attr="I'm" attr2="all" b:attr="sorted" a:attr="out"></e5>
   <e6 xmlns:a="http://www.w3.org">
      <e7 xmlns="http://www.ietf.org">
         <e8 xmlns="">
            <e9 xmlns:a="http://www.ietf.org" attr="default"></e9>
         </e8>
      </e7>
   </e6>
</doc>},
    'test_c14n_example_3_3() output'
);

test_die_on_error();
test_constants();
test_fh_scope();
test_scrubtext();

sub test_basics {
    my $w = XML::Genx->new();
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ),  0,         'StartDocFile(fh)' );
    is( $w->LastErrorMessage,     'Success', 'LastErrorMessage()' );
    is( $w->GetErrorMessage( 0 ), 'Success', 'GetErrorMessage(0)' );

    is( $w->Comment( 'hello world' ), 0, 'Comment(hello world)' );
    is( $w->PI( qw( ping pong ) ), 0, 'PI(ping pong)' );
    is( $w->StartElementLiteral( 'urn:foo', 'foo' ),
        0, 'StartElementLiteral(urn:foo,foo)' );
    is( $w->AddAttributeLiteral( 'urn:foo', 'baz', 'quux' ),
        0, 'AddAttributeLiteral(urn:foo,baz,quux)' );
    is( $w->AddText( 'bar' ), 0, 'AddText(bar)' );
    is( $w->AddCharacter( ord( "!" ) ), 0, 'AddCharacter(ord(!))' );
    is( $w->EndElement,       0, 'EndElement()' );
    is( $w->EndDocument,      0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_empty_namespace {
    my $w  = XML::Genx->new();
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile(fh)' );
    is(
        $w->StartElementLiteral( '', 'foo' ), 0,
        'StartElementLiteral("",foo)'
    );
    is(
        $w->AddAttributeLiteral( '', bar => 'baz' ), 0,
        'AddAttributeLiteral()'
    );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_undef_namespace {
    my $w  = XML::Genx->new();
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile(fh)' );
    is(
        $w->StartElementLiteral( undef, 'foo' ), 0,
        'StartElementLiteral(undef,foo)'
    );
    is(
        $w->AddAttributeLiteral( undef, bar => 'baz' ), 0,
        'AddAttributeLiteral()'
    );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_no_namespace {
    my $w  = XML::Genx->new();
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile(fh)' );
    is( $w->StartElementLiteral( 'foo' ), 0, 'StartElementLiteral(foo)' );
    is( $w->AddAttributeLiteral( bar => 'baz' ), 0, 'AddAttributeLiteral()' );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_bad_filehandle {
  SKIP: {
        skip 'Need perl 5.8 for in memory file handles.', 1
          if $] < 5.008;

        my $txt = '';
        open( my $fh, '>', \$txt ) or die "open(>\$txt): $!\n";
        my $w = XML::Genx->new;
        eval { $w->StartDocFile( $fh ) };
        like( $@, qr/Bad filehandle/i, 'StartDocFile(bad filehandle)' );
    }
}

sub test_declare_namespace {
    my $w = XML::Genx->new();
    my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
    is( $w->LastErrorMessage, 'Success', 'DeclareNamespace()' );
    isa_ok( $ns, 'XML::Genx::Namespace' );
    can_ok( $ns, qw( GetNamespacePrefix AddNamespace ) );
    # This will return undef until we've actually written some XML...
    is( $ns->GetNamespacePrefix, undef, 'GetNamespacePrefix()' );
}

sub test_declare_element {
    my $w = XML::Genx->new();
    my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
    my $el = $w->DeclareElement( $ns, 'wibble' );
    is( $w->LastErrorMessage, 'Success', 'DeclareElement()' );
    isa_ok( $el, 'XML::Genx::Element' );
    can_ok( $el, qw( StartElement ) );

    my $el2 = $w->DeclareElement( 'wobble' );
    isa_ok( $el2, 'XML::Genx::Element' );
}

sub test_declare_attribute {
    my $w = XML::Genx->new();
    my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
    my $at = $w->DeclareAttribute( $ns, 'wobble' );
    is( $w->LastErrorMessage, 'Success', 'DeclareAttribute()' );
    isa_ok( $at, 'XML::Genx::Attribute' );
    can_ok( $at, qw( AddAttribute ) );

    my $at2 = $w->DeclareAttribute( 'weebl' );
    isa_ok( $at2, 'XML::Genx::Attribute' );
}

sub test_declared_in_use {
    my $w = XML::Genx->new();
    my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
    my $el = $w->DeclareElement( $ns, 'bar' );
    my $at = $w->DeclareAttribute( $ns, 'baz' );
    my $fh = tempfile();

    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    is( $el->StartElement(), 0, 'StartElement()' );
    is( $at->AddAttribute( 'quux' ), 0, 'AddAttribute()' );
    is( $w->EndElement(), 0, 'EndElement()' );
    is( $w->EndDocument(), 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_declared_no_namespace {
    my $w = XML::Genx->new();
    my $el = $w->DeclareElement( undef, 'bar' );
    my $at = $w->DeclareAttribute( undef, 'baz' );
    my $fh = tempfile();

    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    is( $el->StartElement(), 0, 'StartElement()' );
    is( $at->AddAttribute( 'quux' ), 0, 'AddAttribute()' );
    is( $w->EndElement(), 0, 'EndElement()' );
    is( $w->EndDocument(), 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_declared_with_namespace {
    my $w = XML::Genx->new();

    # Default prefix for this namespace is "foo".
    my $nsurl = 'http://example.com/#ns';
    my $ns    = $w->DeclareNamespace( $nsurl, 'foo' );

    # Ask genx to generate a default prefix here.
    my $ns2url = 'http://example.com/#ns2';
    my $ns2    = $w->DeclareNamespace( $ns2url );

    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    is( $w->StartElementLiteral( $nsurl, 'el' ), 0, 'StartElement(el)' );

    # Override and attempt to make it the default namespace.
    is( $ns->AddNamespace( '' ), 0, 'AddNamespace("")' )
        or diag $w->LastErrorMessage;

    # Let it keep whatever prefix genx allocated.
    is( $ns2->AddNamespace(), 0, 'AddNamespace()' )
        or diag $w->LastErrorMessage;
    is(
        $w->AddAttributeLiteral( $ns2url, at => 'val' ), 0,
        'AddAttributeLiteral(ns2url,at,val)'
    );
    is( $w->EndElement(),  0, 'EndElement()' );
    is( $w->EndDocument(), 0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_sender {
    my $out = '';
    my $w   = XML::Genx->new;
    is( $w->StartDocSender( sub { $out .= $_[0] } ), 0, 'StartDocSender()' );
    is(
        $w->StartElementLiteral( undef, 'foo' ), 0,
        'StartElementLiteral(undef,foo)'
    );
    is( $w->AddText( "\x{0100}dam" ), 0, 'AddText(*utf8*)' );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return $out;
}

sub test_astral {
    my $w  = XML::Genx->new;
    my $fh = tempfile();

    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    is( $w->StartElementLiteral( undef, 'monogram-for-earth' ),
        0, 'StartElementLiteral(undef,monogram-for-earth)' );
    is( $w->AddText( "\x{1D300}" ), 0, 'AddText(*astral-utf8*)' );
    is( $w->EndElement,             0, 'EndElement()' );
    is( $w->EndDocument,            0, 'EndDocument()' );
    return fh_contents( $fh );
}

sub test_declared_namespace_in_literal {
    my $w  = XML::Genx->new;
    my $fh = tempfile();

    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    my $ns = $w->DeclareNamespace( "urn:foo", "x" );
    isa_ok( $ns, 'XML::Genx::Namespace' );
    is( $w->StartElementLiteral( $ns, 'foo' ),
        0, 'StartElementLiteral(ns,foo)' );
    is( $w->AddAttributeLiteral( $ns, 'attr', '' ),
        0, 'AddAttributeLiteral(x:attr)' );
    is( $w->EndElement,  0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    return fh_contents( $fh );
}

# Check that start and end tags work according to spec.  This example is
# horrible.  <http://www.w3.org/TR/xml-c14n#Example-SETags>
sub test_c14n_example_3_3 {
    my $fh = tempfile();
    my $w  = XML::Genx->new;
    my $indent = "   ";

    # Attempt to replicate <http://www.w3.org/TR/xml-c14n#Example-SETags>.
    $w->StartDocFile( $fh );
    $w->StartElementLiteral( 'doc' );
    $w->AddText( "\n" . $indent );

    $w->StartElementLiteral( 'e1' );
    $w->EndElement;
    $w->AddText( "\n" . $indent );

    $w->StartElementLiteral( 'e2' );
    $w->EndElement;
    $w->AddText( "\n" . $indent );

    $w->StartElementLiteral( 'e3' );
    $w->AddAttributeLiteral( name => 'elem3' );
    $w->AddAttributeLiteral( id   => 'elem3' );
    $w->EndElement;
    $w->AddText( "\n" . $indent );

    $w->StartElementLiteral( 'e4' );
    $w->AddAttributeLiteral( name => 'elem4' );
    $w->AddAttributeLiteral( id   => 'elem4' );
    $w->EndElement;
    $w->AddText( "\n" . $indent );

    my $ns_a    = $w->DeclareNamespace( 'http://www.w3.org',   'a' );
    my $ns_b    = $w->DeclareNamespace( 'http://www.ietf.org', 'b' );
    my $ns_dflt = $w->DeclareNamespace( 'http://example.org',  '' );

    $w->StartElementLiteral( $ns_dflt, 'e5' );
    $w->AddAttributeLiteral( attr2 => 'all' );
    $w->AddAttributeLiteral( $ns_a, attr => 'out' );
    $w->AddAttributeLiteral( $ns_b, attr => 'sorted' );
    $w->AddAttributeLiteral( attr => "I'm" );
    $w->EndElement;
    $w->AddText( "\n" . $indent );

    $w->StartElementLiteral( 'e6' );
    $ns_a->AddNamespace;
    $w->AddText( "\n" . ($indent x 2) );

    $w->StartElementLiteral( $ns_b, 'e7' );
    $ns_b->AddNamespace( '' );
    $w->AddText( "\n" . ($indent x 3) );

    $w->StartElementLiteral( 'e8' );
    $w->UnsetDefaultNamespace;
    $w->AddText( "\n" . ($indent x 4) );

    $w->StartElementLiteral( 'e9' );
    $ns_b->AddNamespace( 'a' );
    $w->AddAttributeLiteral( attr => 'default' );
    $w->EndElement;    # e9
    $w->AddText( "\n" . ($indent x 3) );

    $w->EndElement;    # e8
    $w->AddText( "\n" . ($indent x 2) );

    $w->EndElement;    # e7
    $w->AddText( "\n" . $indent );

    $w->EndElement;    # e6
    $w->AddText( "\n" );
    $w->EndElement;    # doc
    $w->EndDocument;
    return fh_contents( $fh );
}

sub test_die_on_error {
    my $w = XML::Genx->new;
    cmp_ok( $w->LastErrorCode, '==', 0, 'LastErrorCode() after new()' );
    eval { $w->EndDocument };
    like( $@, qr/^Call out of sequence/, 'EndDocument() sequence error' )
        or diag $@;

    # This is needed because I originally wrote a version that used
    # exception objects where I shouldn't have.  Now that I've switched
    # to plain strings, I expect them to report where they have croaked.
    my $thisfile = __FILE__;
    like( $@, qr/ at \Q$thisfile/, 'Exception reports location.' );

    # This is the new way to determine more exactly what happened.
    cmp_ok( $w->LastErrorCode, '==', GENX_SEQUENCE_ERROR,
        'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;    # Clear error status.
    eval {
        my $ns = $w->DeclareNamespace( 'urn:foo', 'foo' );
        isa_ok( $ns, 'XML::Genx::Namespace' );
        $ns->AddNamespace();
    };
    like( $@, qr/^Call out of sequence/, 'ns->AddNamespace() sequence error' );
    cmp_ok( $w->LastErrorCode, '==', GENX_SEQUENCE_ERROR,
        'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;    # Clear error status.
    eval {
        my $el = $w->DeclareElement( 'foo' );
        isa_ok( $el, 'XML::Genx::Element' );
        $el->StartElement();
    };
    like( $@, qr/^Call out of sequence/, 'el->StartElement() sequence error' );
    cmp_ok( $w->LastErrorCode, '==', GENX_SEQUENCE_ERROR,
        'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;    # Clear error status.
    eval {
        my $at = $w->DeclareAttribute( 'foo' );
        isa_ok( $at, 'XML::Genx::Attribute' );
        $at->AddAttribute( 'bar' );
    };
    like( $@, qr/^Call out of sequence/, 'at->AddAttribute() sequence error' );
    cmp_ok( $w->LastErrorCode, '==', GENX_SEQUENCE_ERROR,
        'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;    # Clear error status.
    eval { $w->StartElementLiteral( "\x01" ) };
    like( $@, qr/^Bad NAME/, 'StartElementLiteral() invalid char');
    cmp_ok( $w->LastErrorCode, '==', GENX_BAD_NAME,
        'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;    # Clear error status.
    eval {
        my $fh = tempfile();
        $w->StartDocFile( $fh );
        $w->StartElementLiteral( "foo" );
        $w->AddAttributeLiteral( "bar" => "\x01" );
    };
    like( $@, qr/^Non XML Character/, 'AddAttributeLiteral() invalid char');
    cmp_ok( $w->LastErrorCode, '==', GENX_NON_XML_CHARACTER,
        'LastErrorCode() after an exception.' );

    $w = XML::Genx->new;    # Clear error status.
    eval {
        my $fh = tempfile();
        $w->StartDocFile( $fh );
        $w->StartElementLiteral( "foo" );
        $w->AddCharacter( 1 );
    };
    like( $@, qr/^Non XML Character/, 'AddCharacter() invalid char');
    cmp_ok( $w->LastErrorCode, '==', GENX_NON_XML_CHARACTER,
        'LastErrorCode() after an exception.' );

}

sub test_constants {
    my $w = XML::Genx->new;
    is( GENX_SUCCESS, 0, 'GENX_SUCCESS' );
    eval { $w->EndDocument };
    cmp_ok( $w->LastErrorCode, '==', GENX_SEQUENCE_ERROR,
        'GENX_SEQUENCE_ERROR' );
}

sub test_fh_scope {
    my $w = XML::Genx->new;
    {
        my $fh = tempfile();
        is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    }
    is( $w->StartElementLiteral( 'foo' ), 0, 'StartElementLiteral(foo)' );
    is( $w->EndElement, 0, 'EndElement()' );
    is( $w->EndDocument, 0, 'EndDocument()' );
    # We don't actually care what's been written at this point.  Just
    # that it *has* been written without blowing up.
    return;
}

sub test_scrubtext {
    my $w = XML::Genx->new();
    is( $w->ScrubText( "abc" ),     "abc", 'ScrubText() all good' );
    is( $w->ScrubText( "abc\x01" ), "abc", 'ScrubText() skips non-xml chars' );
}

sub test_perl_strings {
    my $w  = XML::Genx->new;
    my $fh = tempfile();
    is( $w->StartDocFile( $fh ), 0, 'StartDocFile()' );
    is( $w->StartElementLiteral('foo'), 0, 'StartElementLiteral()');
    is( $w->AddText( do { use bytes; "\xA0" } ), 0, 'AddText(\xA0) as bytes' );
    is( $w->EndElement, 0, 'EndElement()');
    is( $w->EndDocument, 0, 'EndDocument()');
    is( fh_contents($fh), "<foo>\xA0</foo>", 'test_perl_strings');
    return;
}

sub fh_contents {
    my $fh = shift;
    # In perl 5.8+, read proper characters.  I /think/ that perl 5.6
    # tries to autodetect this.
    binmode( $fh, ':utf8' ) if $] >= 5.008;
    seek $fh, 0, 0 or die "seek: $!\n";
    local $/;
    return <$fh>;
}

# vim: set ai et sw=4 syntax=perl :
