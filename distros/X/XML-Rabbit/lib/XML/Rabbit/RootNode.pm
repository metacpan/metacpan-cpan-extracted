use strict;
use warnings;

package XML::Rabbit::RootNode;
$XML::Rabbit::RootNode::VERSION = '0.4.1';
use Moose::Role;
with 'XML::Rabbit::Role::Document';

# ABSTRACT: Root node base class

# Preload XPath attribute traits
use XML::Rabbit::Trait::XPathValue;
use XML::Rabbit::Trait::XPathValueList;
use XML::Rabbit::Trait::XPathValueMap;
use XML::Rabbit::Trait::XPathObject;
use XML::Rabbit::Trait::XPathObjectList;
use XML::Rabbit::Trait::XPathObjectMap;

with 'XML::Rabbit::Role::Node' => {
    'node' => { lazy => 1, builder => '_build__node' },
    'xpc'  => { lazy => 1, builder => '_build__xpc'  },
};


sub _build__node {
    return shift->_document->documentElement();
}


sub _build__xpc {
    my ($self) = @_;
    # XML::LibXML loads this class, see XML::Rabbit::Role::Document
    my $xpc = XML::LibXML::XPathContext->new( $self->_document );

    # Make sure namespace_map is inherited from XML::Rabbit::Role::Node
    confess("Required role 'XML::Rabbit::Role::Node' not composed") unless $self->does('XML::Rabbit::Role::Node');

    # Register all prefixes specified in namespace_map for use in xpath queries
    foreach my $prefix ( keys %{ $self->namespace_map } ) {
        $xpc->registerNs($prefix, $self->namespace_map->{$prefix});
    }
    return $xpc;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Rabbit::RootNode - Root node base class

=head1 VERSION

version 0.4.1

=head1 SYNOPSIS

    package MyXMLSyntax;
    use Moose;
    with 'XML::Rabbit::RootNode';

    has title => (
        isa         => 'Str',
        traits      => [qw(XPathValue)],
        xpath_query => '/root/title',
    );

    no Moose;
    __PACKAGE__->meta->make_immutable();

    1;

=head1 DESCRIPTION

This module provides the base node attribute used to hold the root of the XML document.

See L<XML::Rabbit> for a more complete example.

=head1 ATTRIBUTES

=head2 node

An instance of a L<XML::LibXML::Node> class representing the root node of an
XML document. Read Only.

It is lazily loaded from the C<document> attribute, which is inherited from
L<XML::Rabbit::Role::Document>.

=head2 xpc

An instance of a L<XML::LibXML::XPathContext> class initialized with the
C<node> attribute. Read Only.

If a subclass has an attribute named C<namespace_map> which is a HashRef it
is used to initialize namespaces using the C<registerNs> method. This is
required on XML files that use namespaces, like XHTML.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
