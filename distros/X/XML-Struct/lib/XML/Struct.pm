package XML::Struct;

use strict;
use XML::LibXML::Reader;
use XML::Struct::Reader;
use XML::Struct::Writer;
use XML::Struct::Simple;

our $VERSION = '0.26';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(readXML writeXML simpleXML removeXMLAttr textValues);

sub readXML { # ( [$from], %options )
    my (%options) = @_ % 2 ? (from => @_) : @_;

    my %reader_options = (
        map { $_ => delete $options{$_} }
        grep { exists $options{$_} }
        qw(attributes whitespace path stream simple micro root ns depth content deep)
    );
    if (%options) {
        if (exists $options{from} and keys %options == 1) {
            $reader_options{from} = $options{from};
        } else {
            $reader_options{from} = \%options;
        }
    }

    XML::Struct::Reader->new( %reader_options )->readDocument;
}

sub writeXML {
    my ($xml, %options) = @_;
    XML::Struct::Writer->new(%options)->write($xml); 
}

sub simpleXML {
    my ($element, %options) = @_;
    XML::Struct::Simple->new(%options)->transform($element);
}

*removeXMLAttr = *XML::Struct::Simple::removeXMLAttr;

# TODO: document (better name?)
sub textValues {
    my ($element, $options) = @_;
    # TODO: %options (e.g. join => " ")

    my $children = $element->[2];
    return "" if !$children;

    return join "", grep { $_ ne "" } map {
        ref $_ ?  textValues($_, $options) : $_
    } @$children;
}

1;
__END__

=encoding utf8

=head1 NAME

XML-Struct - Represent XML as data structure preserving element order

=begin markdown

# Status

[![Build Status](https://travis-ci.org/nichtich/XML-Struct.png)](https://travis-ci.org/nichtich/XML-Struct)
[![Coverage Status](https://coveralls.io/repos/nichtich/XML-Struct/badge.png)](https://coveralls.io/r/nichtich/XML-Struct)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/XML-Struct.png)](http://cpants.cpanauthors.org/dist/XML-Struct)

=end markdown

=head1 SYNOPSIS

    use XML::Struct qw(readXML writeXML simpleXML removeXMLAttr);

    my $xml = readXML( "input.xml" );
    # [ root => { xmlns => 'http://example.org/' }, [ '!', [ x => {}, [42] ] ] ]

    my $doc = writeXML( $xml );
    # <?xml version="1.0" encoding="UTF-8"?>
    # <root xmlns="http://example.org/">!<x>42</x></root>

    my $simple = simpleXML( $xml, root => 'record' );
    # { record => { xmlns => 'http://example.org/', x => 42 } }

    my $xml2 = removeXMLAttr($xml);
    # [ root => [ '!', [ x => [42] ] ] ]

=head1 DESCRIPTION

L<XML::Struct> implements a mapping between XML and Perl data structures. By
default, the mapping preserves element order, so it also suits for
"document-oriented" XML.  In short, an XML element is represented as array
reference with three parts:

   [ $name => \%attributes, \@children ]

This data structure corresponds to the abstract data model of
L<MicroXML|http://www.w3.org/community/microxml/>, a simplified subset of XML.

If your XML documents don't contain relevant attributes, you can also choose
to map to this format:

   [ $name => \@children ]

Both parsing (with L<XML::Struct::Reader> or function C<readXML>) and
serializing (with L<XML::Struct::Writer> or function C<writeXML>) are fully
based on L<XML::LibXML>, so performance is better than L<XML::Simple> and
similar to L<XML::LibXML::Simple>.

=head1 MODULES

=over

=item L<XML::Struct::Reader>

Parse XML as stream into XML data structures.

=item L<XML::Struct::Writer>

Write XML data structures to XML streams for serializing, SAX processing, or
creating a DOM object.

=item L<XML::Struct::Writer::Stream>

Simplified SAX handler for XML serialization.

=item L<XML::Struct::Simple>

Transform XML data structure into simple form. 

=back

=head1 FUNCTIONS

The following functions are exported on request:

=head2 readXML( $source [, %options ] )

Read an XML document with L<XML::Struct::Reader>. The type of source (string,
filename, URL, IO Handle...) is detected automatically. Options not known to
XML::Struct::Reader are passed to L<XML::LibXML::Reader>.

=head2 writeXML( $xml [, %options ] )

Write an XML document/element with L<XML::Struct::Writer>.

=head2 simpleXML( $element [, %options ] )

Transform an XML document/element into simple key-value format as known from
L<XML::Simple>. See L<XML::Struct::Simple> for configuration options.

=head2 removeXMLAttr( $element )

Transform XML structure with attributes to XML structure without attributes.
The function does not modify the passed element but creates a modified copy.

=head1 EXAMPLE

To give an example, with L<XML::Struct::Reader>, this XML document:

    <root>
      <foo>text</foo>
      <bar key="value">
        text
        <doz/>
      </bar>
    </root>

is transformed to this structure:

    [
      "root", { }, [
        [ "foo", { }, "text" ],
        [ "bar", { key => "value" }, [
          "text", 
          [ "doz", { }, [ ] ]
        ] 
      ]
    ]

This module also supports a simple key-value (aka "data-oriented") format, as
used by L<XML::Simple>. With option C<simple> (or function C<simpleXML>) the
document given above would be transformed to this structure:

    {
        foo => "text",
        bar => {
            key => "value",
            doz => {}
        }
    }

=head1 SEE ALSO

This module was first created to be used in L<Catmandu::XML> and turned out to
also become a replacement for L<XML::Simple>. See the former for more XML
processing.

L<XML::Twig> is another popular and powerfull module for stream-based
processing of XML documents.

See L<XML::Smart>, L<XML::Hash::LX>, L<XML::Parser::Style::ETree>,
L<XML::Fast>, and L<XML::Structured> for different representations of XML data
as data structures (feel free to implement converters from/to XML::Struct).
L<XML::GenericJSON> seems to be an outdated and incomplete attempt to capture
more parts of XML Infoset in another data structure.

See JSONx for a kind of reverse direction (JSON in XML).

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
