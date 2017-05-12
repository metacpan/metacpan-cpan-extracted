package W3C::SOAP::XSD::Document::Element;

# Created on: 2012-05-26 19:04:09
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
use W3C::SOAP::Utils qw/split_ns xml_error/;

extends 'W3C::SOAP::XSD::Document::Type';

our $VERSION = 0.14;

has complex_type => (
    is     => 'rw',
    isa    => 'Str',
    builder => '_complex_type',
    lazy    => 1,
);
has type => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_type',
    lazy       => 1,
    predicate  => 'has_type',
);
has package => (
    is     => 'rw',
    isa    => 'Str',
    builder => '_package',
    lazy    => 1,
);
has max_occurs => (
    is     => 'rw',
    #isa    => 'Str',
    builder => '_max_occurs',
    lazy    => 1,
);
has min_occurs => (
    is     => 'rw',
    #isa    => 'Str',
    builder => '_min_occurs',
    lazy    => 1,
);
has nillable => (
    is     => 'rw',
    isa    => 'Bool',
    builder => '_nillable',
    lazy    => 1,
);
has choice_group => (
    is     => 'rw',
    isa    => 'Int',
);

sub _complex_type {
    my ($self) = @_;
    my $complex;
    my @nodes = $self->document->xpc->findnodes('xsd:complexType', $self->node);

    for my $node (@nodes) {
    }

    return $complex;
}

sub _type {
    my ($self) = @_;
    my $type = $self->node->getAttribute('type');
    return $type if $type;

    my $simple = $self->document->simple_type;
    TYPE:
    for my $type (keys %{$simple}) {
        my $node = $simple->{$type}->node;
        my  $type_name = $node->parentNode->getAttribute('name');
        if ( $type_name && $self->name && $type_name eq $self->name ) {
            my @children = $self->document->xpc->findnodes('xsd:restriction', $node);
            last if @children != 1;

            my $child = $children[0]->firstChild;
            while ($child) {
                last TYPE if $child->nodeName !~ /^[#]/xms;
                $child = $child->nextSibling;
            }

            return $children[0]->getAttribute('base');
        }
        $type_name ||= '';
    }

    return $self->has_anonymous;
}

sub _package {
    my ($self) = @_;
    my $type = $self->type;
    my ($ns, $name) = split_ns($type);
    $ns ||= $self->document->ns_name;
    my $ns_uri = $name ? $self->document->get_ns_uri($ns, $self->node) : '';
    $name ||= $ns;

    if ( $ns_uri eq 'http://www.w3.org/2001/XMLSchema' ) {
        return "xs:$name";
    }

    my $base = $self->document->get_module_name( $ns_uri || $self->document->target_namespace );

    return $base . '::' . $name;
}

sub _max_occurs {
    my ($self) = @_;
    return $self->node->getAttribute('maxOccurs') || 1;
}

sub _min_occurs {
    my ($self) = @_;
    return $self->node->getAttribute('minOccurs') || 0;
}

sub _nillable {
    my ($self) = @_;
    my $nillable = $self->node->getAttribute('nillable');

    return !$nillable          ? 1
        : $nillable eq 'true'  ? 1
        : $nillable eq 'false' ? 0
        :                        die "Unknown value for attribute nillable in ".$self->node->toString;
}

sub module {
    my ($self) = @_;

    return $self->document->module;
}

sub type_module {
    my ($self) = @_;
    my ($ns, $type) = split_ns($self->type);
    $ns ||= $self->document->ns_name;
    my $ns_uri = $self->document->get_ns_uri($ns, $self->node);

    return $self->simple_type || $self->document->get_module_name( $ns_uri ) . '::' . $type;
}

sub simple_type {
    my ($self) = @_;
    $self->document->simple_type();
    my ($ns, $type) = split_ns($self->type);
    $ns ||= $self->document->ns_name;
    return "xs:$type"
        if $self->document->ns_map->{$ns}
            && $self->document->ns_map->{$ns} eq 'http://www.w3.org/2001/XMLSchema';

    my $ns_uri = $self->document->get_ns_uri($ns, $self->node);
    warn "Simple type missing a type for '".$self->type."'\n".xml_error($self->node)."\n"
        if !$ns && $ns_uri ne 'http://www.w3.org/2001/XMLSchema';

    return "xs:$type" if $ns_uri eq 'http://www.w3.org/2001/XMLSchema';

    my @xsds = ($self->document);
    while ( my $xsd = shift @xsds ) {
        my $simple = $xsd->simple_type;
        if ( !$simple && @{ $xsd->simple_types } ) {
            $simple = $xsd->simple_type($xsd->_simple_type);
            #warn $xsd->target_namespace . " $type => $simple\n" if $type eq 'GetCreateUIDResponseDto';
        }

        return $simple->{$type}->moose_type if $simple && $simple->{$type};

        push @xsds, @{$xsd->imports};
    }
    return;
}

sub very_simple_type {
    my ($self) = @_;
    $self->document->simple_type();
    my ($ns, $type) = split_ns($self->type);
    $ns ||= $self->document->ns_name;
    return "xs:$type" if $self->document->ns_map->{$ns} && $self->document->ns_map->{$ns} eq 'http://www.w3.org/2001/XMLSchema';

    my $ns_uri = $self->document->get_ns_uri($ns, $self->node);
    warn "Simple type missing a type for '".$self->type."'\n".xml_error($self->node)."\n"
        if !$ns && $ns_uri ne 'http://www.w3.org/2001/XMLSchema';

    return "xs:$type" if $ns_uri eq 'http://www.w3.org/2001/XMLSchema';

    my @xsds = ($self->document);
    while ( my $xsd = shift @xsds ) {
        my $simple = $xsd->simple_type;
        if ( !$simple && @{ $xsd->simple_types } ) {
            $simple = $xsd->simple_type($xsd->_simple_type);
        }

        return $simple->{$type}->type if $simple && $simple->{$type};

        push @xsds, @{$xsd->imports};
    }
    return;
}

sub moosex_type {
    my ($self) = @_;
    my ($ns, $type) = split_ns($self->type);
    $ns ||= $self->document->ns_name;
    my $ns_uri = $self->document->get_ns_uri($ns, $self->node);
    warn "Simple type missing a type for '".$self->type."'\n".xml_error($self->node)."\n"
        if !$ns && $ns_uri ne 'http://www.w3.org/2001/XMLSchema';

    return "'xs:$type'" if $ns_uri eq 'http://www.w3.org/2001/XMLSchema';

    my @xsds = ($self->document);
    while ( my $xsd = shift @xsds ) {
        my $simple = $xsd->simple_type;
        if ( !$simple && @{ $xsd->simple_types } ) {
            $simple = $xsd->simple_type($xsd->_simple_type);
            #warn $xsd->target_namespace . " $type => $simple\n" if $type eq 'GetCreateUIDResponseDto';
        }

        return $simple->{$type}->moosex_type if $simple && $simple->{$type};

        push @xsds, @{$xsd->imports};
    }
    return;
}

sub has_anonymous {
    my ($self) = @_;
    return if $self->has_type && $self->type;

    my %map = reverse %{ $self->document->ns_map };

    my $simple = $self->document->simple_type;
    for my $type (keys %{$simple}) {
        my  $type_name = $simple->{$type}->node->parentNode->getAttribute('name');
        if ( $type_name && $self->name && $type_name eq $self->name ) {
            return $map{$self->document->target_namespace} . ':' . $type;
        }
        $type_name ||= '';
    }

    my $complex = $self->document->complex_type;
    for my $type (keys %{$complex}) {
        my  $type_name = $complex->{$type}->node->parentNode->getAttribute('name');
        if ( $type_name && $self->name && $type_name eq $self->name ) {
            return $map{$self->document->target_namespace} . ':' . $type;
        }
        $type_name ||= '';
    }

    $self->document->ns_map->{xs} ||= 'http://www.w3.org/2001/XMLSchema';
    return 'xs:string';
}

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Document::Element - XML Schema Element

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Document::Element version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::XSD::Document::Element;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=over 4

=item C<module ()>

=item C<type_module ()>

=item C<very_simple_type ()>

=item C<simple_type ()>

=item C<moosex_type ()>

=item C<has_anonymous ()>

=back

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
