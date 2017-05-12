use strict;
use warnings;

package XML::Rabbit::Role::Node;
$XML::Rabbit::Role::Node::VERSION = '0.4.1';
use MooseX::Role::Parameterized;

use Encode ();

# ABSTRACT: Base role for all nodes


parameter 'node'          => ( isa => 'HashRef', default => sub { +{} } );


parameter 'xpc'           => ( isa => 'HashRef', default => sub { +{} } );


parameter 'namespace_map' => ( isa => 'HashRef', default => sub { +{} } );

role {
    my ($p) = @_;

    has '_xpc' => (
        is       => 'ro',
        isa      => 'XML::LibXML::XPathContext',
        reader   => 'xpc',
        init_arg => 'xpc',
        %{ $p->xpc }
    );

    has '_node' => (
        is       => 'ro',
        isa      => 'XML::LibXML::Node',
        reader   => 'node',
        init_arg => 'node',
        %{ $p->node }
    );

    has 'namespace_map' => (
        is       => 'ro',
        isa      => 'HashRef[Str]',
        lazy     => 1,
        default  => sub { +{} },
        %{ $p->namespace_map },
    );

};


sub dump_xml {
    my ($self) = @_;
    return $self->node->toString(1);
}

no MooseX::Role::Parameterized;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Rabbit::Role::Node - Base role for all nodes

=head1 VERSION

version 0.4.1

=head1 SYNOPSIS

See L<XML::Rabbit::RootNode> or L<XML::Rabbit::Node> for examples.

=head1 DESCRIPTION

This module provides attributes and methods common to all nodes.

See L<XML::Rabbit> for a more complete example.

=head1 ATTRIBUTES

=head2 node

An instance of a L<XML::LibXML::Node> class representing the a node in an XML document. Read Only.

=head2 xpc

An instance of a L<XML::LibXML::XPathContext> class initialized with the C<node> attribute. Read Only.

=head2 namespace_map

A HashRef of strings that defines the prefix/namespace XML mappings for the
XPath parser. Usually overriden in a subclass like this:

    has '+namespace_map' => (
        default => sub { {
            myprefix      => "http://my.example.com",
            myotherprefix => "http://other.example2.org",
        } },
    );

=head1 METHODS

=head2 dump_xml

Dumps the XML of the current node as a native perl string.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
