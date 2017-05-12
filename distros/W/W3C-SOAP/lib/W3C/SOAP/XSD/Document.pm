package W3C::SOAP::XSD::Document;

# Created on: 2012-05-26 15:46:31
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp qw/carp croak cluck confess longmess/;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;
use XML::LibXML;
use WWW::Mechanize;
use Try::Tiny;
use URI;
use W3C::SOAP::Exception;
use W3C::SOAP::XSD::Document::Element;
use W3C::SOAP::XSD::Document::ComplexType;
use W3C::SOAP::XSD::Document::SimpleType;
use W3C::SOAP::Utils qw/normalise_ns ns2module/;

extends 'W3C::SOAP::Document';

our $VERSION = 0.14;

has element_form_default => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_element_form_default',
    lazy       => 1,
);
has imports => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document]',
    builder    => '_imports',
    lazy       => 1,
);
has includes => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document]',
    builder    => '_includes',
    lazy       => 1,
);
has simple_types => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document::SimpleType]',
    builder    => '_simple_types',
    lazy       => 1,
);
has simple_type => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document::SimpleType]',
    builder    => '_simple_type',
    lazy       => 1,
);
has anon_simple_type_count => (
    is      => 'ro',
    isa     => 'Int',
    traits  => [qw/Counter/],
    default => -1,
    handles => { simple_type_count => 'inc' },
);
has complex_types => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document::ComplexType]',
    builder    => '_complex_types',
    lazy       => 1,
);
has complex_type => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document::ComplexType]',
    builder    => '_complex_type',
    lazy       => 1,
);
has anon_complex_type_count => (
    is      => 'ro',
    isa     => 'Int',
    traits  => [qw/Counter/],
    default => -1,
    handles => { complex_type_count => 'inc' },
    clearer => 'reset_complex_type_count',
    lazy    => 1,
);
has elements => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document::Element]',
    builder    => '_elements',
    lazy       => 1,
);
has element => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document::Element]',
    builder    => '_element',
    lazy       => 1,
);
has module => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_module',
    lazy       => 1,
);
has ns_name => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_ns_name',
    lazy       => 1,
);
has ns_map => (
    is         => 'rw',
    isa        => 'HashRef[Str]',
    predicate  => 'has_ns_map',
    builder    => '_ns_map',
    lazy       => 1,
);

sub _element_form_default {
    my ($self) = @_;
    my @imports;
    my @nodes = $self->xpc->findnodes('//@elementFormDefault');

    if (@nodes) {
        return $nodes[0]->value;
    }

    return 'unqualified';
}

sub _imports {
    my ($self) = @_;
    my @imports;
    my @nodes = $self->xpc->findnodes('//xsd:import');

    for my $import (@nodes) {
        next if $import->getAttribute('namespace') && $import->getAttribute('namespace') eq 'http://www.w3.org/2001/XMLSchema';

        my $location = $import->getAttribute('schemaLocation') || $import->getAttribute('namespace');
        if ($location) {

            if ( $self->location && (
                    $self->location =~ m{^(?:https?|ftp)://}xms
                    || (
                        -f $self->location
                        && !-f $location
                    )
                )
            ) {
                my $current_location
                    = -f $self->location
                    ? path($self->location)->absolute . ''
                    : $self->location;

                $location = URI->new_abs($location, $current_location)->as_string;
            }

            push @imports, __PACKAGE__->new(
                location      => $location,
                ns_module_map => $self->ns_module_map,
                module_base   => $self->module_base,
            );
        }
        else {
            warn "Found import but no schemaLocation so no schema imported!\n\t" . $import->toString . "\n\t";
        }
    }

    return \@imports;
}

sub _includes {
    my ($self) = @_;
    my @includes;
    my @nodes = $self->xpc->findnodes('//xsd:include');

    for my $include (@nodes) {
        next if $include->getAttribute('namespace') && $include->getAttribute('namespace') eq 'http://www.w3.org/2001/XMLSchema';

        my $location = $include->getAttribute('schemaLocation') || $include->getAttribute('namespace');
        if ($location) {

            if ( $self->location && $self->location =~ m{^(?:https?|ftp)://}xms ) {
                $location = URI->new_abs($location, $self->location)->as_string;
            }

            push @includes, __PACKAGE__->new(
                location      => $location,
                ns_module_map => $self->ns_module_map,
                module_base   => $self->module_base,
            );
        }
        else {
            warn "Found include but no schemaLocation so no schema included!\n\t" . $include->toString . "\n\t";
        }
    }

    return \@includes;
}

sub _simple_types {
    my ($self) = @_;
    my @simple_types;
    my @nodes = $self->xpc->findnodes('//xsd:simpleType');

    for my $node (@nodes) {
        push @simple_types, W3C::SOAP::XSD::Document::SimpleType->new(
            document => $self,
            node   => $node,
        );
    }

    return \@simple_types;
}

sub _simple_type {
    my ($self) = @_;
    my %simple_type;

    for my $type (@{ $self->simple_types }) {
        my $name = $type->name;
        if ( !$name ) {
            my $parent = $type->node->parentNode;
            $name = $parent->getAttribute('name');
            $name = $name ? $name . '_type' : 'anon'.$self->simple_type_count;
            $type->name($name);
        }
        confess "No name for simple type ".$type->node->parentNode->toString if !$name;
        $simple_type{$name} = $type;
    }

    return \%simple_type;
}

sub _complex_types {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('/*/xsd:complexType');
    push @nodes, $self->xpc->findnodes('/*/xsd:complexContent');

    for my $node (@nodes) {
        # get all top level complex types
        try {
            push @complex_types, W3C::SOAP::XSD::Document::ComplexType->new(
                document => $self,
                node     => $node,
            );
        }
        catch {
            warn Dumper {
                document => $self,
                node     => $node,
            };
            die $_;
        };

    }

    # now itterate over all document level elements and elements of complex types
    my @elements = ( @{ $self->elements }, map {@{ $_->sequence }} @complex_types );

    while ( my $element = shift @elements ) {
        # Get the elements first sub complex type (if any)
        my ($node) = $self->xpc->findnodes('xsd:complexType', $element->node);
        if (!$node) {
            ($node) = $self->xpc->findnodes('xsd:complexContent', $element->node);
        }
        next unless $node;

        try {
            push @complex_types, W3C::SOAP::XSD::Document::ComplexType->new(
                parent_node => $element,
                document    => $self,
                node        => $node,
            );
            push @elements, @{ $complex_types[-1]->sequence };
        }
        catch  {
            warn Dumper {
                parent_node => $element->node->toString,
                document    => $self,
                node        => $node,
            };
            die $_;
        };
    }

    # Moved the typification of the names in here from
    # the complex_type builder as I can't see why you
    # wouldn't want the name fixed up front.
    for my $type (@complex_types) {
        my $name = $type->name;
        if ( !$name ) {
            my $parent = $type->node->parentNode;
            $name = $parent->getAttribute('name');
            $name = $name ? $name . 'Type' : 'Anon'.$self->complex_type_count;
            $type->name($name);
        }
        confess "No name for complex type ".$type->node->parentNode->toString if !$name;
    }

    return \@complex_types;
}

sub _complex_type {
    my ($self) = @_;
    my %complex_type;
    for my $type (@{ $self->complex_types }) {
        my $name = $type->name;
        $complex_type{$name} = $type;
    }

    return \%complex_type;
}

sub _elements {
    my ($self) = @_;
    my @elements;
    my @nodes = $self->xpc->findnodes('/*/xsd:element');

    for my $node (@nodes) {
        push @elements, W3C::SOAP::XSD::Document::Element->new(
            document => $self,
            node   => $node,
        );
    }

    return \@elements;
}

sub _element {
    my ($self) = @_;
    my %element;
    for my $element (@{ $self->elements }) {
        $element{$element->name} = $element;
    }
    return \%element;
}

sub _ns_name {
    my ($self) = @_;
    my %rev = reverse %{ $self->ns_map };
    if ( !defined $rev{$self->target_namespace} ) {
        delete $self->ns_map->{''};
        my $ns = $self->target_namespace;
        $ns =~ s/:/_/gxms;
        $rev{$self->target_namespace} = $ns;
        $self->ns_map->{$ns} = $self->target_namespace;
    }
    return $rev{$self->target_namespace};
}

sub _ns_map {
    my ($self) = @_;

    my %map
        = map {
            ( $_->name =~ /^xmlns:?(.*)$/xms => $_->value )
        }
        grep {
            $_->name =~ /^xmlns/xms
        }
        $self->xml->getDocumentElement->getAttributes;

    my %rev;
    for my $name ( keys %map ) {
        $rev{$map{$name}} = defined $rev{$map{$name}} ? $rev{$map{$name}} : $name;
    }
    if ( $rev{$self->target_namespace} && $map{''} && $map{''} eq $self->target_namespace ) {
        delete $map{''};
    }

    my $ns = $self->target_namespace;
    $ns =~ s/:/_/gxms;
    $map{$ns} = $self->target_namespace if !$rev{$self->target_namespace};
    $map{''} = '';

    return \%map;
}

sub get_ns_uri {
    my ($self, $ns_name, $node) = @_;
    confess "No namespace passed when trying to map a namespace uri!\n" if !defined $ns_name;

    return $self->ns_map->{$ns_name} if $self->ns_map->{$ns_name};

    if ( $ns_name =~ /:/xms ) {
        my $tmp_ns_name = $ns_name;
        $tmp_ns_name =~ s/:/_/gxms;
        return $self->ns_map->{$tmp_ns_name} if $self->ns_map->{$tmp_ns_name};
    }

    while ($node) {
        my $ns = $node->getAttribute("xmlns:$ns_name");
        return $ns if $ns;
        $ns = $node->getAttribute("targetNamespace");
        return $ns if $ns;
        $node = $node->parentNode;
        last if ref $node eq 'XML::LibXML::Document';
    }

    confess "Couldn't find the namespace '$ns_name' to map\nMap has:\n", Dumper $self->ns_map if !defined $self->ns_map->{$ns_name};

    return $self->ns_map->{$ns_name};
}

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Document - Represents a XMLSchema Document

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Document version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::XSD::Document;

   my $xsd = W3C::SOAP::XSD::Document->new(
        location => 'my.xsd',
        ns_base => {
            'http://xml.namespace.com/SomeTing.html' => 'MyApp::SomeTing',
        },
   );

=head1 DESCRIPTION

Takes a XMLSchema Document and makes the contents available in a convenient
interface.

=head1 SUBROUTINES/METHODS

=over 4

=item C<get_ns_uri ()>

=back

=head1 ATTRIBUTES

=over 4

=item C<imports>

=item C<includes>

=item C<simple_types>

=item C<simple_type>

=item C<complex_types>

=item C<complex_type>

=item C<elements>

=item C<element>

=item C<module>

=item C<ns_map>

=item C<ns_module_map>

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close Hornsby Heights NSW Australia).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
