# @(#) $Id: basic.t,v 1.1 2002/12/04 12:40:10 dom Exp $

use strict;
use warnings;

use Test::More 'no_plan';

use XML::Filter::Namespace;
use XML::SAX;
use XML::SAX::ParserFactory;
use XML::SAX::Writer;

{
    my $xfn = XML::Filter::Namespace->new;
    isa_ok( $xfn, 'XML::Filter::Namespace' );
}

my $ns = 'urn:foo';
my $alt_ns = 'urn:bar';

my @parsers = map { $_->{Name} } @{ XML::SAX->parsers };
# NB: Have to sort by shortest parser first so that XML::SAX::ParserFactory
# loads them all in correctly.
foreach my $parser ( sort { length $a <=> length $b } @parsers ) {
    # Unfortunately, this parser has a few problems with namespaces.
    next if $parser eq 'XML::LibXML::SAX';

    local $XML::SAX::ParserPackage = $parser;
    my $xfn = XML::Filter::Namespace->new;
    $xfn->ns( $ns );
    run_tests( $xfn, $ns, $alt_ns );
}

sub run_tests {
    my ( $xfn, $ns, $alt_ns ) = @_;
    test_sax(
        $xfn,
        "<f:root xmlns:f='$ns'>Text</f:root>",
        "<root xmlns='$ns'>Text</root>",
        "stripped plain element",
    );

    test_sax(
        $xfn,
        "<f:root xmlns:f='$ns'>Text<f:element /></f:root>",
        "<root xmlns='$ns'>Text<element /></root>",
        "stripped nested element",
    );

    test_sax(
        $xfn,
        "<f:root xmlns:f='$ns' xmlns:b='$alt_ns'>Text<b:element /></f:root>",
        "<root xmlns='$ns'>Text</root>",
        "removed nested element in alternative namespace",
    );

    test_sax(
        $xfn,
        "<f:root xmlns:f='$ns' f:attr='value'>Text</f:root>",
        "<root xmlns='$ns' attr='value'>Text</root>",
        "stripped attribute",
    );

    test_sax(
        $xfn,
        "<f:root xmlns:f='$ns' attr='value'>Text</f:root>",
        "<root xmlns='$ns'>Text</root>",
        "removed attribute in empty namespace",
    );

    test_sax(
        $xfn,
        "<f:root xmlns:f='$ns' xmlns:b='$alt_ns'>Text</f:root>",
        "<root xmlns='$ns'>Text</root>",
        "removed alternative namespace",
    );

    test_sax(
        $xfn,
"<f:root xmlns:f='$ns' xmlns:b='$alt_ns'><f:b xmlns:f='$ns'>Text</f:b></f:root>",
        "<root xmlns='$ns'><b>Text</b></root>",
        "removed duplicated namespace declaration",
    );

    test_sax(
        $xfn,
"<f:root xmlns:f='$ns' xmlns:b='$alt_ns'><Z:b xmlns:Z='$ns'>Text</Z:b></f:root>",
        "<root xmlns='$ns'><b>Text</b></root>",
        'removed duplicated namespace declaration with different prefix',
    );

    test_sax(
        $xfn,
"<f:root xmlns:f='$ns' f:attr='value' xmlns:b='$alt_ns' b:attr='glork'>Text</f:root>",
        "<root xmlns='$ns' attr='value'>Text</root>",
        "removed attribute in alternative namespace",
    );

    $xfn->nl_after_tag( { element => 1 } );
    test_sax(
        $xfn,
        "<f:root xmlns:f='$ns'>Text<f:element /></f:root>",
        "<root xmlns='$ns'>Text<element />\n</root>",
        "inserted newline after correct element",
    );

    {
        my $warns = '';
        local $SIG{ __WARN__ } = sub { $warns = "@_" };
        $xfn->publicid( "$ns publicid" );
        test_sax(
            $xfn,
            "<f:root xmlns:f='$ns'>Text</f:root>",
            qr/<!DOCTYPE root PUBLIC '$ns publicid' ''\s*>/,
            "inserted doctype with publicid",
        );
        like(
            $warns,
            qr/public id specified with no system id/,
            'warned about no systemid'
        );
    }

    $xfn->systemid( "$ns systemid" );
    test_sax(
        $xfn,
        "<f:root xmlns:f='$ns'>Text</f:root>",
        qr/<!DOCTYPE root PUBLIC '$ns publicid' '$ns systemid'\s*>/,
        "inserted doctype with publicid and systemid",
    );
}

#---------------------------------------------------------------------

sub test_sax {
    my ( $h, $input, $expected, $test_name ) = @_;
    my $result = '';
    my $w = XML::SAX::Writer->new( Output => \$result );
    $h->set_handler( $w );
    my $p = XML::SAX::ParserFactory->parser( Handler => $h );
    $p->parse_string( $input );
    # Use like() rather than is() because different sax processors may
    # put things slightly differently...
    $expected = qr/\Q$expected\E/
        unless ref $expected;
    like( $result, $expected, $test_name . " (" . ref($p) . ")" );
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 syntax=perl :
