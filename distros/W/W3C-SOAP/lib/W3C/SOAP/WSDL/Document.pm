package W3C::SOAP::WSDL::Document;

# Created on: 2012-05-27 18:57:29
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use XML::LibXML;
use W3C::SOAP::XSD::Document;
use W3C::SOAP::WSDL::Document::Binding;
use W3C::SOAP::WSDL::Document::Message;
use W3C::SOAP::WSDL::Document::PortType;
use W3C::SOAP::WSDL::Document::Service;

extends 'W3C::SOAP::Document';

our $VERSION = 0.14;

has messages => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Message]',
    builder    => '_messages',
    lazy       => 1,
);
has message => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::Message]',
    builder    => '_message',
    lazy       => 1,
    weak_ref   => 1,
);
has port_types => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::PortType]',
    builder    => '_port_types',
    lazy       => 1,
);
has port_type => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::PortType]',
    builder    => '_port_type',
    lazy       => 1,
    weak_ref   => 1,
);
has bindings => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Binding]',
    builder    => '_bindings',
    lazy       => 1,
);
has binding => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::Binding]',
    builder    => '_binding',
    lazy       => 1,
    weak_ref   => 1,
);
has services => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Service]',
    builder    => '_services',
    lazy       => 1,
);
has service => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::Service]',
    builder    => '_service',
    lazy       => 1,
    weak_ref   => 1,
);
has policies => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Policy]',
    builder    => '_policies',
    lazy       => 1,
    weak_ref   => 1,
);
has policy => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::Policy]',
    builder    => '_policy',
    lazy       => 1,
    weak_ref   => 1,
);
has schemas => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document]',
    builder    => '_schemas',
    lazy       => 1,
);
has schema => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document]',
    builder    => '_schema',
    lazy       => 1,
    weak_ref   => 1,
);

sub _messages {
    my ($self) = @_;
    my @messages;
    my @nodes = $self->xpc->findnodes('//wsdl:message');

    for my $node (@nodes) {
        push @messages, W3C::SOAP::WSDL::Document::Message->new(
            document => $self,
            node   => $node,
        );
    }

    return \@messages;
}

sub _message {
    my ($self) = @_;
    my %message;
    for my $message ( @{ $self->messages }) {
        $message{$message->name} = $message;
    }

    return \%message;
}

sub _port_types {
    my ($self) = @_;
    my @port_types;
    my @nodes = $self->xpc->findnodes('//wsdl:portType');

    for my $node (@nodes) {
        push @port_types, W3C::SOAP::WSDL::Document::PortType->new(
            document => $self,
            node   => $node,
        );
    }

    return \@port_types;
}

sub _port_type {
    my ($self) = @_;
    my %port_type;
    for my $port_type ( @{ $self->port_type }) {
        $port_type{$port_type->name} = $port_type;
    }

    return \%port_type;
}

sub _bindings {
    my ($self) = @_;
    my @bindings;
    my @nodes = $self->xpc->findnodes('//wsdl:binding');

    for my $node (@nodes) {
        push @bindings, W3C::SOAP::WSDL::Document::Binding->new(
            document => $self,
            node   => $node,
        );
    }

    return \@bindings;
}

sub _binding {
    my ($self) = @_;
    my %binding;
    for my $binding ( @{ $self->binding }) {
        $binding{$binding->name} = $binding;
    }

    return \%binding;
}

sub _services {
    my ($self) = @_;
    my @services;
    my @nodes = $self->xpc->findnodes('//wsdl:service');

    for my $node (@nodes) {
        push @services, W3C::SOAP::WSDL::Document::Service->new(
            document => $self,
            node   => $node,
        );
    }

    return \@services;
}

sub _service {
    my ($self) = @_;
    my %service;
    for my $service ( @{ $self->service }) {
        $service{$service->name} = $service;
    }

    return \%service;
}

sub _policies {
    my ($self) = @_;
    my @policies;
    my @nodes = $self->xpc->findnodes('/*/wsp:Policy');

    for my $node (@nodes) {
        push @policies, W3C::SOAP::WSDL::Document::Policy->new(
            document => $self,
            node     => $node,
        );
    }

    return \@policies;
}

sub _policy {
    my ($self) = @_;
    my %service;
    for my $service ( @{ $self->service }) {
        $service{$service->sec_id} = $service;
    }

    return \%service;
}

sub _schemas {
    my ($self) = @_;
    my @schemas;
    my @nodes = $self->xpc->findnodes('//wsdl:types/*');

    for my $node (@nodes) {
        next if $node->getAttribute('namespace') && $node->getAttribute('namespace') eq 'http://www.w3.org/2001/XMLSchema';

        # merge document namespaces into the schema's tags
        my $doc = $self->xml->getDocumentElement;
        my @attribs = $doc->getAttributes;
        for my $ns ( grep {$_->name =~ /^xmlns:/ && !$node->getAttribute($_->name)} @attribs ) {
            $node->setAttribute( $ns->name, 'value' );
            $node->setAttribute( $ns->name, $ns->value );
        }

        my @args;
        if ( $self->has_module_base ) {
            my $base = $self->module_base;
            $base =~ s/WSDL/XSD/;
            $base .= '::XSD' if $base !~ /XSD/;
            push @args, ( module_base => $base );
        }

        push @schemas, W3C::SOAP::XSD::Document->new(
            string        => $node->toString,
            ns_module_map => $self->ns_module_map,
            @args,
        );
        $schemas[-1]->location($self->location);
        $schemas[-1]->target_namespace;
    }

    return \@schemas;
}

sub _schema {
    my ($self) = @_;
    my %schema;
    for my $schema ( @{ $self->schemas }) {
        $schema{$schema->target_namespace} = $schema;
    }

    return \%schema;
}

sub get_nsuri {
    my ($self, $ns) = @_;
    my ($node) = $self->xpc->findnodes("//namespace::*[name()='$ns']");
    return $node->value;
}

sub xsd_modules {
    my ($self) = @_;
    my %modules;

    for my $service (@{ $self->services }) {
        for my $port (@{ $service->ports }) {
            for my $operation (@{ $port->binding->operations }) {
                if ( $operation->port_type->outputs->[0] && $operation->port_type->outputs->[0]->message->element ) {
                    $modules{$operation->port_type->outputs->[0]->message->element->module}++;
                }
            }
        }
    }

    return ( sort keys %modules );
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Document - Object to represent a WSDL Document

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Document version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Document;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

Top level look at a WSDL, supplies access to messages, services etc defined
in the WSDL.

=head1 SUBROUTINES/METHODS

=over 4

=item C<get_nsuri ()>

=item C<xsd_modules ()>

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
