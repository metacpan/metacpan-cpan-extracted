use strict;
use warnings;

package XML::Rabbit::Trait::XPathValueList;
$XML::Rabbit::Trait::XPathValueList::VERSION = '0.4.1';
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


sub _build_default {
    my ($self) = @_;
    return sub {
        my ($parent) = @_;
        my $xpath_query = $self->_resolve_xpath_query( $parent );
        my @nodes;
        foreach my $node ( $self->_find_nodes( $parent, $xpath_query ) ) {
            push @nodes, $node->to_literal . "";
        }
        return \@nodes;
    };
}

Moose::Util::meta_attribute_alias('XPathValueList');

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Rabbit::Trait::XPathValueList - Multiple value xpath extractor trait

=head1 VERSION

version 0.4.1

=head1 SYNOPSIS

    package MyXMLSyntaxNode;
    use Moose;
    with 'XML::Rabbit::RootNode';

    has all_references => (
        isa         => 'ArrayRef[Str]',
        traits      => [qw(XPathValueList)],
        xpath_query => '//@href|//@src',
    );

    no Moose;
    __PACKAGE__->meta->make_immutable();

    1;

=head1 DESCRIPTION

This module provides the extraction of primitive values from an XML node based on an XPath query.

See L<XML::Rabbit> for a more complete example.

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
