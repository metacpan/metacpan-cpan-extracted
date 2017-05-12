use strict;
use warnings;

package XML::Rabbit::Trait::XPathValue;
$XML::Rabbit::Trait::XPathValue::VERSION = '0.4.1';
use Moose::Role;

with 'XML::Rabbit::Trait::XPath';

# ABSTRACT: Single value xpath extractor trait


sub _build_default {
    my ($self) = @_;
    return sub {
        my ($parent) = @_;
        my $node = $self->_find_node(
            $parent,
            $self->_resolve_xpath_query( $parent ),
        );
        return blessed($node) ? $node->to_literal . "" : "";
    };
}

Moose::Util::meta_attribute_alias('XPathValue');

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Rabbit::Trait::XPathValue - Single value xpath extractor trait

=head1 VERSION

version 0.4.1

=head1 SYNOPSIS

    package MyXMLSyntaxNode;
    use Moose;
    with 'XML::Rabbit::Node';

    has title => (
        isa         => 'Str',
        traits      => [qw(XPathValue)],
        xpath_query => './@title',
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
