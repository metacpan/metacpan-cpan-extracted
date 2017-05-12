use strict;
use warnings;

package XML::Rabbit::Role::Document;
$XML::Rabbit::Role::Document::VERSION = '0.4.1';
use Moose::Role;

use XML::LibXML 1.69 ();
use Encode ();

# ABSTRACT: XML Document base class


has '_file' => (
    is        => 'ro',
    isa       => 'Str',
    init_arg  => 'file',
    predicate => '_has_file',
);


has '_fh' => (
    is        => 'ro',
    isa       => 'GlobRef',
    init_arg  => 'fh',
    predicate => '_has_fh',
);


has '_xml' => (
    is        => 'ro',
    isa       => 'Str',
    init_arg  => 'xml',
    predicate => '_has_xml',
);


has '_document' => (
    is         => 'ro',
    isa        => 'XML::LibXML::Document',
    lazy_build => 1,
    init_arg   => 'dom',
);

sub _build__document {
    my ( $self ) = @_;
    my $doc;
    # Priority source order is: file, fh, xml (string) if multiple defined
    $doc = $self->_parser->parse_file(   $self->_file ) if $self->_has_file;
    $doc = $self->_parser->parse_fh(     $self->_fh   ) if $self->_has_fh and not defined($doc);
    $doc = $self->_parser->parse_string( $self->_xml  ) if $self->_has_xml and not defined($doc);
    confess("No input specified. Please specify argument file, fh, xml or dom.\n") unless $doc;
    return $doc;
}

has '_parser' => (
    is      => 'ro',
    isa     => 'XML::LibXML',
    lazy    => 1,
    default => sub { XML::LibXML->new( huge => 1 ), },
);


sub dump_document_xml {
    my ( $self ) = @_;
    return Encode::decode(
        $self->_document->actualEncoding,
        $self->_document->toString(1),
    );
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Rabbit::Role::Document - XML Document base class

=head1 VERSION

version 0.4.1

=head1 SYNOPSIS

    package MyXMLSyntax;
    use Moose;
    with 'XML::Rabbit::Role::Document';

    sub root_node {
        return shift->_document->documentElement();
    }

=head1 DESCRIPTION

This module provides the base document attribute used to hold the parsed XML content.

See L<XML::Rabbit> for a more complete example.

=head1 ATTRIBUTES

=head2 _file

A string representing the path to the file that contains the XML document data. Read Only. Constructor parameter is C<file>.

=head2 _fh

A glob reference / file handle that points to the XML document data. Read Only. Constructor parameter is C<fh>.

=head2 _xml

A binary string containing the XML document data. Read Only. Constructor parameter is C<xml>.

=head2 _document

An instance of an L<XML::LibXML::Document> class. Read Only. Constructor parameter is C<dom>.

=head1 METHODS

=head2 dump_document_xml

Dumps the XML of the entire document as a native perl string.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
