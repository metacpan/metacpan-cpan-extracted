package W3C::SOAP::XSD::Document::SimpleType;

# Created on: 2012-05-26 19:04:19
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

has type => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_type',
    lazy       => 1,
);
has list => (
    is         => 'rw',
    isa        => 'Bool',
    builder    => '_list',
    lazy       => 1,
);
has enumeration => (
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    builder    => '_enumeration',
    lazy       => 1,
);
has pattern => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    builder    => '_pattern',
    predicate  => 'has_pattern',
    lazy       => 1,
);
has maxLength => (
    is         => 'rw',
    isa        => 'Maybe[Int]',
    builder    => '_maxLength',
    predicate  => 'has_minLength',
    lazy       => 1,
);
has minLength => (
    is         => 'rw',
    isa        => 'Maybe[Int]',
    builder    => '_minLength',
    predicate  => 'has_maxLength',
    lazy       => 1,
);
has length => (
    is         => 'rw',
    isa        => 'Maybe[Int]',
    builder    => '_length',
    predicate  => 'has_length',
    lazy       => 1,
);

sub _type {
    my ($self) = @_;
    my ($restriction) = $self->document->xpc->findnodes('xsd:restriction', $self->node);

    return $restriction->getAttribute('base') if $restriction;

    ($restriction) = $self->document->xpc->findnodes('xsd:list/xsd:simpleType/xsd:restriction', $self->node);

    return $restriction->getAttribute('base');
}

sub _list {
    my ($self) = @_;
    my ($restriction) = $self->document->xpc->findnodes('xsd:list', $self->node);

    return $restriction ? 1 : undef;
}

sub _enumeration {
    my ($self) = @_;
    my @nodes = $self->document->xpc->findnodes('xsd:restriction/xsd:enumeration', $self->node);
    my @enumeration;

    for my $node (@nodes) {
        push @enumeration, $node->getAttribute('value');
    }

    return \@enumeration;
}

sub _pattern   { return shift->_build_restriction('pattern')   }
sub _maxLength { return shift->_build_restriction('maxLength') }
sub _minLength { return shift->_build_restriction('minLength') }
sub _length    { return shift->_build_restriction('length')    }
sub _build_restriction {
    my ($self, $type) = @_;
    my ($node) = $self->document->xpc->findnodes("xsd:restriction/xsd:$type", $self->node);
    return $node->getAttribute('value');
}

sub moose_type {
    my ($self) = @_;

    warn "No name for ".$self->node->toString if !$self->name;
    my $type = $self->document->module . ':' . $self->name;

    return $type;
}

sub moose_base_type {
    my ($self) = @_;
    my ($ns, $type) = split_ns($self->type);
    $ns ||= $self->document->target_namespace;
    return "xs:$type" if $self->document->ns_map->{$ns} && $self->document->ns_map->{$ns} eq 'http://www.w3.org/2001/XMLSchema';

    my $ns_uri = $self->document->get_ns_uri($ns, $self->node);

    return "xs:$type" if $ns_uri eq 'http://www.w3.org/2001/XMLSchema';

    return $type;
}

sub moosex_type {
    my ($self) = @_;

    warn "No name for ".$self->node->toString if !$self->name;
    return $self->name;
}

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Document::SimpleType - Represents simpleType elements of XSD documents

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Document::SimpleType version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::XSD::Document::SimpleType;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=over 4

=item C<moose_type ()>

=item C<moose_base_type ()>

=item C<moosex_type ()>

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
