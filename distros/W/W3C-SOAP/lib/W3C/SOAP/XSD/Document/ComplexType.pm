package W3C::SOAP::XSD::Document::ComplexType;

# Created on: 2012-05-26 19:04:25
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use W3C::SOAP::Utils qw/split_ns/;

extends 'W3C::SOAP::XSD::Document::Type';

our $VERSION = 0.14;

has sequence => (
    is      => 'rw',
    isa     => 'ArrayRef[W3C::SOAP::XSD::Document::Element]',
    builder => '_sequence',
    lazy    => 1,
);
has module => (
    is        => 'rw',
    isa       => 'Str',
    builder   => '_module',
    lazy       => 1,
);
has complex_content => (
    is        => 'rw',
    isa       => 'Str',
    builder   => '_complex_content',
    lazy       => 1,
);
has extension => (
    is        => 'rw',
    isa       => 'Maybe[Str]',
    builder   => '_extension',
    lazy       => 1,
);

sub _sequence {
    my ($self) = @_;
    my ($node) = $self->document->xpc->findnodes('xsd:complexContent/xsd:extension', $self->node);
    if (!$node) {
        ($node) = $self->document->xpc->findnodes('xsd:extension', $self->node);
    }

    return $self->_get_sequence_elements($node || $self->node);
}

sub _module {
    my ($self) = @_;

    return $self->document->module . '::' . ( $self->name || $self->parent_node->name );
}

sub _complex_content {
    my ($self) = @_;

    return $self->document->module . '::' . ( $self->name || $self->parent_node->name );
}

sub _extension {
    my ($self) = @_;

    # TODO $suffix feels like a hack, it fixes the tests but isn't really calculated to be the correct value
    my $suffix = '';
    my @nodes = $self->document->xpc->findnodes('xsd:complexContent/xsd:extension', $self->node);
    if (!@nodes) {
        @nodes = $self->document->xpc->findnodes('xsd:extension', $self->node);
        $suffix = 'Type';
    }

    for my $node (@nodes) {
        my ($ns, $tag) = split_ns($node->getAttribute('base'));
        my $ns_uri = $self->document->get_ns_uri($ns, $self->node);

        return $self->document->get_module_name( $ns_uri ) . "::$tag" . $suffix;
    }

    return;
}

sub _get_sequence_elements {
    my ($self, $node) = @_;
    my @nodes = $self->document->xpc->findnodes('xsd:sequence/*', $node);
    my @sequence;
    my $group = 1;

    for my $node (@nodes) {
        if ( $node->nodeName =~ /(?:^|:)element$/ ) {
            push @sequence, W3C::SOAP::XSD::Document::Element->new(
                parent_node => $self,
                node   => $node,
            );
        }
        elsif ( $node->nodeName =~ /(?:^|:)choice$/ ) {
            my @choices = $self->document->xpc->findnodes('xsd:element', $node);
            for my $choice (@choices) {
                push @sequence, W3C::SOAP::XSD::Document::Element->new(
                    parent_node  => $self,
                    node         => $choice,
                    choice_group => $group,
                );
            }
            $group++;
        }
    }

    return \@sequence;
}

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Document::ComplexType - Represents complexType elements of XSD documents

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Document::ComplexType version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::XSD::Document::ComplexType;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Represents a single XML Schema complex type definition.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
