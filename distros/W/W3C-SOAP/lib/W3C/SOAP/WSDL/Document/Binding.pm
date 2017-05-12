package W3C::SOAP::WSDL::Document::Binding;

# Created on: 2012-05-27 19:25:33
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
use W3C::SOAP::WSDL::Document::Operation;

extends 'W3C::SOAP::Document::Node';

our $VERSION = 0.14;

has style => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_style',
    lazy       => 1,
);
has transport => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_transport',
    lazy       => 1,
);
has operations => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Operation]',
    builder    => '_operations',
    lazy       => 1,
);

sub _style {
    my ($self) = @_;
    my $style = $self->node->getAttribute('style');
    return $style if $style;
    my ($child) = $self->document->xpc->findnode('soap:binding'. $self->node);
    return $child->getAttribute('style');
}

sub _transport {
    my ($self) = @_;
    my $transport = $self->node->getAttribute('transport');
    return $transport if $transport;
    my ($child) = $self->document->xpc->findnode('soap:binding'. $self->node);
    return $child->getAttribute('transport');
}

sub _operations {
    my ($self) = @_;
    my @operations;
    my @nodes = $self->document->xpc->findnodes('wsdl:operation', $self->node);

    for my $node (@nodes) {
        push @operations, W3C::SOAP::WSDL::Document::Operation->new(
            parent_node   => $self,
            node     => $node,
        );
    }

    return \@operations;
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Document::Binding - Bindings for WSDL documents

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Document::Binding version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Document::Binding;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A C<W3C::SOAP::WSDL::Document::Binding> represents the bindings tags in a WSDL
document.

=head1 SUBROUTINES/METHODS

=over 4

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
