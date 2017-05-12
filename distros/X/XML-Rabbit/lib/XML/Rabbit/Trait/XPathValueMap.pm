use strict;
use warnings;

package XML::Rabbit::Trait::XPathValueMap;
$XML::Rabbit::Trait::XPathValueMap::VERSION = '0.4.1';
use Moose::Role;

with 'XML::Rabbit::Trait::XPath';

# ABSTRACT: Multiple value xpath extractor trait

around '_process_options' => sub {
    my ($orig, $self, $name, $options, @rest) = @_;

    $self->$orig($name, $options, @rest);

    # This should really be:
    # has '+isa' => ( required => 1 );
    # but for some unknown reason Moose doesn't allow that
    confess("isa attribute is required") unless defined( $options->{'isa'} );
};


has 'xpath_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has 'xpath_value' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


sub _build_default {
    my ($self) = @_;
    return sub {
        my ($parent) = @_;
        my $xpath_query = $self->_resolve_xpath_query( $parent );
        my %node_map;
        foreach my $node ( $self->_find_nodes( $parent, $xpath_query ) ) {
            my $key = $parent->xpc->findvalue( $self->xpath_key, $node );
            if ( defined($key) and length $key > 0 ) {
                my $value = $parent->xpc->findvalue( $self->xpath_value, $node );
                $node_map{$key} = $value;
            }
        }
        return \%node_map;
    };
}

Moose::Util::meta_attribute_alias('XPathValueMap');

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Rabbit::Trait::XPathValueMap - Multiple value xpath extractor trait

=head1 VERSION

version 0.4.1

=head1 SYNOPSIS

    package MyXMLSyntaxNode;
    use Moose;
    with 'XML::Rabbit::RootNode';

    has reference_map => (
        isa         => 'HashRef[Str]',
        traits      => [qw(XPathValueMap)],
        xpath_query => '//*[@href]',
        xpath_key   => './@href',
        xpath_value => './@title';
    );

    no Moose;
    __PACKAGE__->meta->make_immutable();

    1;

=head1 DESCRIPTION

This module provides the extraction of primitive values from an XML node based on an XPath query.

See L<XML::Rabbit> for a more complete example.

=head1 ATTRIBUTES

=head2 xpath_key

The xpath query that specifies what will be put in the key in the hash. Required.

=head2 xpath_value

The xpath query that specifies what will be put in the value in the hash. Required.

=head1 METHODS

=head2 _build_default

Returns a coderef that is run to build the default value of the parent attribute. Read Only.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
