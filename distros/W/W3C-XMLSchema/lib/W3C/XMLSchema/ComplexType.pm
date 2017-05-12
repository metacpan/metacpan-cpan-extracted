use strict;
use warnings;

package W3C::XMLSchema::ComplexType;
{
  $W3C::XMLSchema::ComplexType::VERSION = '0.0.4';
}
use XML::Rabbit;

# ABSTRACT: XMLSchema ComplexType Definition


has_xpath_value 'name' => './@name';


has_xpath_value 'mixed' => './@mixed';


has_xpath_object_list 'items' => './*',
    {
        'xsd:group'          => 'W3C::XMLSchema::Group',
        'xsd:attributeGroup' => 'W3C::XMLSchema::AttributeGroup',
    },
;

finalize_class();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

W3C::XMLSchema::ComplexType - XMLSchema ComplexType Definition

=head1 VERSION

version 0.0.4

=head1 DESCRIPTION

ComplexTypes, as defined by XMLSchema definition.

See L<W3C::XMLSchema> for a more complete example.

=head1 ATTRIBUTES

=head2 name

Name given to complex type.

=head2 mixed

True if complex type contains mixed content.

=head2 items

A list of items in the complex type. Instances of L<W3C::XMLSchema::Group>
or L<W3C::XMLSchema::AttributeGroup>. A ComplexType is by definition
composed of simple types, either elements or attributes.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
