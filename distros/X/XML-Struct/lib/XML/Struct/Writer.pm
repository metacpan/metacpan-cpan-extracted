package XML::Struct::Writer;
use strict;

use Moo;
use XML::LibXML::SAX::Builder;
use XML::Struct::Writer::Stream;
use Scalar::Util qw(blessed reftype);
use Carp;

our $VERSION = '0.26';

has attributes => (is => 'rw', default => sub { 1 });
has encoding   => (is => 'rw', default => sub { 'UTF-8' });
has version    => (is => 'rw', default => sub { '1.0' });
has standalone => (is => 'rw');
has pretty     => (is => 'rw', default => sub { 0 }); # 0|1|2
has xmldecl    => (is => 'rw', default => sub { 1 });
has handler    => (is => 'lazy', builder => 1);

has to => (
    is => 'rw',
    coerce => sub {
        if (!ref $_[0]) {
            return IO::File->new($_[0], 'w');
        } elsif (reftype($_[0]) eq 'SCALAR') {
            open my $io,">:utf8",$_[0]; 
            return $io;
        } else { # IO::Handle, GLOB, ...
            return $_[0];
        }
    },
    trigger => sub { delete $_[0]->{handler} }
);

sub _build_handler { 
    $_[0]->to ? XML::Struct::Writer::Stream->new(
        fh       => $_[0]->to,
        encoding => $_[0]->encoding,
        version  => $_[0]->version,
        pretty   => $_[0]->pretty,
    ) : XML::LibXML::SAX::Builder->new( handler => $_[0] ); 
}

sub write {
    my ($self, $element, $name) = @_;

    $self->writeStart;
    $self->writeElement(
        $self->microXML($element, $name // 'root')
    );
    $self->writeEnd;
    
    $self->handler->can('result') ? $self->handler->result : 1;
}

*writeDocument = \&write;

# TODO: Make available as function in XML::Struct or XML::Struct::Simple
sub microXML {
    my ($self, $element, $name) = @_;

    my $type = reftype($element);
    if ($type) {
        # MicroXML
        if ($type eq 'ARRAY') {
            if (@$element == 1) {
                return $element;
            } elsif (@$element == 2) { 
                if ( (reftype($element->[1]) // '') eq 'ARRAY') {
                    return [ $element->[0], {}, $element->[1] ];
                } elsif (!$self->attributes and %{$element->[1]}) {
                    return [ $element->[0] ];
                } else {
                    return $element;
                }
            } else {
                if (!$self->attributes and %{$element->[1]}) {
                    return [ $element->[0], {}, $element->[2] ];
                } else {
                    return $element;
                }
            }
        # SimpleXML
        } elsif ($type eq 'HASH') {
            my $children = [
                map {
                    my ($tag, $content) = ($_, $element->{$_});
                    # text
                    if (!ref $content) {
                        [ $tag, {}, [$content] ]
                    } elsif (reftype($content) eq 'ARRAY') {
                        @$content
                            ? map { [ $tag, {}, [$_] ] } @$content
                            : [ $tag ]; 
                    } elsif (reftype $content  eq 'HASH' ) {
                        [ $tag, {}, [ $content ] ];
                    } else {
                        ();
                    }
                }
                grep { defined $element->{$_} }
                sort keys %$element
            ];
            return $name ? [ $name, {}, $children ] : @$children;
        }
    }

    croak "expected XML as ARRAY or HASH reference";
}

sub writeElement {
    my $self = shift;
    
    foreach my $element (@_) {
        $self->writeStartElement($element);
        foreach my $child ( @{ $element->[2] // [] } ) {
            if (ref $child) {
                $self->writeElement( $self->microXML($child) );
            } else {
                $self->writeCharacters($child);
            }
        }

        $self->writeEndElement($element);
    }
}

sub writeStartElement {
    my ($self, $element) = @_;

    my $args = { Name => $element->[0] };
    $args->{Attributes} = $element->[1] if $element->[1];

    $self->handler->start_element($args); 
}

sub writeEndElement {
    my ($self, $element) = @_;
    $self->handler->end_element({ Name => $element->[0] });
}

sub writeCharacters {
    $_[0]->handler->characters({ Data => $_[1] });
}

sub writeStart {
    my $self = shift;
    $self->handler->start_document;
    if ($self->handler->can('xml_decl') && $self->xmldecl) {
        $self->handler->xml_decl({
            Version => $self->version, 
            Encoding => $self->encoding,
            Standalone => $self->standalone,
        });
    }
    $self->writeStartElement(@_) if @_;
}

sub writeEnd {
    my $self = shift;
    $self->writeEndElement(@_) if @_;
    $self->handler->end_document;
}

1;
__END__

=encoding UTF-8

=head1 NAME

XML::Struct::Writer - Write XML data structures to XML streams

=head1 SYNOPSIS

    use XML::Struct::Writer;

    # serialize
    XML::Struct::Writer->new(
        to => \*STDOUT,
        attributes => 0,
        pretty => 1,
    )->write( [
        doc => [ 
            [ name => [ "alice" ] ],
            [ name => [ "bob" ] ],
        ] 
    ] );

    # <?xml version="1.0" encoding="UTF-8"?>
    # <doc>
    #  <name>alice</name>
    #  <name>bob</name>
    # </doc>

    # create DOM
    my $xml = XML::Struct::Writer->new->write( [
        greet => { }, [
            "Hello, ",
            [ emph => { color => "blue" } , [ "World" ] ],
            "!"
        ]
    ] ); 
    $xml->toFile("greet.xml");

    # <?xml version="1.0" encoding="UTF-8"?>
    # <greet>Hello, <emph color="blue">World</emph>!</greet>

=head1 DESCRIPTION

This module writes an XML document, given as L<XML::Struct> data structure, as
stream of L</"SAX EVENTS">. The default handler receives these events with
L<XML::LibXML::SAX::Builder> to build a DOM tree which can then be used to
serialize the XML document as string.  The writer can also be used to directly
serialize XML with L<XML::Struct::Writer::Stream>.

L<XML::Struct> provides the shortcut function C<writeXML> to this module.

XML elements can be passed in any of these forms and its combinations:

    # MicroXML:

     [ $name => \%attributes, \@children ]

     [ $name => \%attributes ]

     [ $name ] 

    # lax MicroXML also:

     [ $name => \@children ]

    # SimpleXML:

     { $name => \@children, $name => $content,  ... }

=head1 CONFIGURATION

A XML::Struct::Writer can be configured with the following options:

=over

=item to

Filename, L<IO::Handle>, string reference, or other kind of stream to directly
serialize XML to with L<XML::Struct::Writer::Stream>. This option is ignored
if C<handler> is explicitly set.

=item handler

A SAX handler to send L</"SAX EVENTS"> to. If neither this option nor C<to> is
explicitly set, an instance of L<XML::LibXML::SAX::Builder> is used to build a
DOM.

=item attributes

Ignore XML attributes if set to false. Set to true by default.

=item xmldecl

Include XML declaration on serialization. Enabled by default.

=item encoding

An encoding (for handlers that support an explicit encoding). Set to UTF-8
by default.

=item version

The XML version. Set to C<1.0> by default.

=item standalone

Add standalone flag in the XML declaration.

=item pretty

Pretty-print XML. Disabled by default. 

=back

=head1 METHODS

=head2 write( $root [, $name ] ) == writeDocument( $root [, $name ] )

Write an XML document, given as array reference (lax MicroXML), hash reference
(SimpleXML), or both mixed. If given as hash reference, the name of a root tag
can be chosen or it is set to C<root>. This method is basically equivalent to:

    $writer->writeStart;
    $writer->writeElement(
        $writer->microXML($root, $name // 'root')
    );
    $writer->writeEnd;
    $writer->result if $writer->can('result');

The remaining methods expect XML in MicroXML format only.

=head2 writeElement( $element [, @more_elements ] )

Write one or more XML elements and their child elements to the handler.

=head2 writeStart( [ $root [, $name ] ] )

Call the handler's C<start_document> and C<xml_decl> methods. An optional root
element can be passed, so C<< $writer->writeStart($root) >> is equivalent to:

    $writer->writeStart;
    $writer->writeStartElement($root);

=head2 writeStartElement( $element )

Directly call the handler's C<start_element> method.

=head2 writeEndElement( $element )

Directly call the handler's C<end_element> method.

=head2 writeCharacters( $string )

Directy call the handler's C<characters> method.

=head2 writeEnd( [ $root ] )

Directly call the handler's C<end_document> method. An optional root element
can be passed, so C<< $writer->writeEnd($root) >> is equivalent to:

    $writer->writeEndElement($root);
    $writer->writeEnd;

=head2 microXML( $element [, $name ] )

Convert an XML element, given as array reference (lax MicroXML) or as hash
reference (SimpleXML) to a list of MicroXML elements and optionally remove
attributes. Does not affect child elements.

=head1 SAX EVENTS

A SAX handler, set with option C<handler>, is expected to implement the
following methods (two of them are optional):

=over

=item xml_decl( { Version => $version, Encoding => $encoding } )

Optionally called once at the start of an XML document, if the handler supports
this method.

=item start_document()

Called once at the start of an XML document.

=item start_element( { Name => $name, Attributes => \%attributes } )

Called at the start of an XML element to emit an XML start tag.

=item end_element( { Name => $name } )

Called at the end of an XML element to emit an XML end tag.

=item characters( { Data => $characters } )

Called for character data. Character entities and CDATA section are expanded to
strings.

=item end_document()

Called once at the end of an XML document.

=item result()

Optionally called at the end of C<write>/C<writeDocument> to return a value
from this methods. Handlers do not need to implement this method.

=back

=head1 SEE ALSO

Using a streaming SAX handler, such as L<XML::SAX::Writer>,
L<XML::Genx::SAXWriter>, L<XML::Handler::YAWriter>, and possibly L<XML::Writer>
should be more performant for serialization. Examples of other modules that
receive SAX events include L<XML::STX>, L<XML::SAX::SimpleDispatcher>, and
L<XML::SAX::Machines>,

=cut
