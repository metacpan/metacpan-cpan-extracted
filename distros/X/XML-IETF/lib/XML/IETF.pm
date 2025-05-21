package XML::IETF;
# ABSTRACT: an interface to the IETF XML Registry.
use Carp;
use Carp::Always;
use Data::Mirror qw(mirror_xml mirror_file);
use URI;
use URI::Namespace;
use XML::LibXML;
use constant REGISTRY_URL => 'https://www.iana.org/assignments/xml-registry/xml-registry.xml';
use feature qw(state);
use vars qw($VERSION $REGISTRY);
use strict;
use warnings;

$VERSION = '0.01';

state $REGISTRY;


sub xmlns {
    my ($class, $value) = @_;

    foreach my $record ($class->get_registry('ns')->getElementsByTagName('record')) {
        if ($value eq $record->getElementsByTagName('value')->shift->textContent) {
            return URI::Namespace->new($record->getElementsByTagName('name')->shift->textContent);
        }
    }

    return undef;
}


sub name {
    my ($class, $xmlns) = @_;
    $xmlns = $xmlns->as_string if ($xmlns->isa('URI::Namespace'));

    foreach my $record ($class->get_registry('ns')->getElementsByTagName('record')) {
        if ($xmlns eq $record->getElementsByTagName('name')->shift->textContent) {
            return $record->getElementsByTagName('value')->shift->textContent;
        }
    }
}


sub schemaLocation {
    my ($class, $xmlns) = @_;

    my $name = $class->name($xmlns);

    foreach my $record ($class->get_registry('schema')->getElementsByTagName('record')) {
        if ($name eq $record->getElementsByTagName('value')->shift->textContent) {
            return URI->new_abs(
                $record->getElementsByTagName('file')->shift->textContent,
                REGISTRY_URL,
            )
        }
    }

    return undef;
}


sub xsd {
    my ($class, @uris) = @_;

    if (1 == scalar(@uris)) {
        my $url = $class->schemaLocation($uris[0]);

        return !$url ? undef : XML::LibXML::Schema->new(location => mirror_file($url));

    } else {
        my %xsd;

        foreach my $uri (@uris) {
            my $name = $class->name($uri);
            croak("Bad URI '$uri'") unless ($name);

            $xsd{$name} = mirror_file($class->schemaLocation($uri));
            croak("Bad URI '$uri'") unless ($xsd{$name});
        }

        my $xsd = XML::LibXML::Document->new;
        my $schema = $xsd->createElementNS('http://www.w3.org/2001/XMLSchema', 'schema');
        $xsd->setDocumentElement($schema);

        foreach my $uri (keys(%xsd)) {
            my $import = $schema->appendChild($xsd->createElement('import'));
            $import->setAttribute(namespace => $uri);
            $import->setAttribute(schemaLocation => $xsd{$uri});
        }

        return XML::LibXML::Schema->new(string => $xsd->toString);
    }
}

sub get_registry {
    my ($class, $sub) = @_;

    $REGISTRY ||= mirror_xml(REGISTRY_URL);

    foreach my $el ($REGISTRY->getElementsByTagName('registry')) {
        if ($el->hasAttribute('id') && $sub eq $el->getAttribute('id')) {
            return $el;
        }
    }

    return undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::IETF - an interface to the IETF XML Registry.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    $xmlns = XML::IETF->xmlns('netconf'); # returns a URI::Namespace object

    $url = XML::IETF->schemaLocation($xmlns); # returns a URI object

    $xsd = XML::IETF->xsd($xmlns); # returns an XML::LibXML::Schema object

    $xsd = XML::IETF->xsd(@uris); # returns a synthesised XML::LibXML::Schema object

=head1 DESCRIPTION

C<XML::IETF> provides a simple interface to the IETF XML Registry, specified in
L<RFC 3688|https://www.rfc-editor.org/rfc/rfc3688.html>.

This permits for example, dynamically retrieval and loading of XML schema files
using only their target namespace or mnemonic name. This is quite useful for
schema-heavy protocols such as L<EPP|Net::EPP>.

This module uses L<Data::Mirror> to retrieve remote resources from the IANA.

=head1 PACKAGE METHODS

=head2 xmlns($value)

This method returns a L<URI::Namespace> object for the XML namespace URI that is
associated with C<$value>, or C<undef> if the record cannot be found.

=head2 name($xmlns)

This method is the reverse of C<xmlns()>: given an XML namespace, it returns
the mnemonic name that the namespace is registered with. C<$xmlns> may be a
string or a L<URI::Namespace> object.

=head2 schemaLocation($xmlns)

This method returns a L<URI> object which locates the XSD file that is
associated with the XML namespace URI in C<$xmlns>, which may be a string or a
L<URI::Namespace> object, or C<undef> if the record cannot be found.

=head2 xsd($uri|@uris)

This method has two forms:

=over

=item * If a single argument (C<$uri>) is provided, it returns a
L<XML::LibXML::Schema> object containg the XML schema that is associated with
the XML namespace URI in C<$uri>, which may be a string or a L<URI::Namespace>
object, or C<undef> if the record cannot be found.

=item * If an array of URIs (C<@uris>) is provided, it will synthesise a
schema that imports the XML schema of each XML namespace URI that is provided.
If any of the provided URIs cannot be resolved to an XML schema, it will throw
an exception.

=back

=head1 EXAMPLE

The following code will generate an XSD that can be used to validate all EPP
command and response frames described by the base EPP protocol
(L<STD 69|https://datatracker.ietf.org/doc/std95/>):

    $xsd = XML::IETF->xsd(map { XML::IETF->xmlns($_) } qw(
        eppcom-1.0
        epp-1.0
        domain-1.0
        host-1.0
    ));

Adding support for EPP extensions is simply a matter of extending the array of
mnemonics, for example:

    $xsd = XML::IETF->xsd(map { XML::IETF->xmlns($_) } qw(
        eppcom-1.0
        epp-1.0
        domain-1.0
        host-1.0
        secDNS-1.0
        rgp-1.0
        launch-1.0 mark-1.0 signedMark-1.0
    ));

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
