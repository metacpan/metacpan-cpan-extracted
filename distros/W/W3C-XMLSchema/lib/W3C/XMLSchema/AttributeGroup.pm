use strict;
use warnings;

package W3C::XMLSchema::AttributeGroup;
{
  $W3C::XMLSchema::AttributeGroup::VERSION = '0.0.4';
}
use XML::Rabbit;

# ABSTRACT: XMLSchema Attribute Group Definition


has_xpath_value 'name' => './@name';


has_xpath_value 'ref' => './@ref';


has_xpath_object_list 'attribute_groups' => './xsd:attributeGroup' => 'W3C::XMLSchema::AttributeGroup';


has_xpath_object_list 'attributes' => './xsd:attribute' => 'W3C::XMLSchema::Attribute';

finalize_class();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

W3C::XMLSchema::AttributeGroup - XMLSchema Attribute Group Definition

=head1 VERSION

version 0.0.4

=head1 DESCRIPTION

AttributeGroups, as defined by XMLSchema definition.

See L<W3C::XMLSchema> for a more complete example.

=head1 ATTRIBUTES

=head2 name

Name given to attribute group.

=head2 ref

Name of other AttributeGroup this attribute group references.

=head2 attribute_groups

Child AttributeGroup of this AttributeGroup. Mostly used for referencing other AttributeGroups.

=head2 attributes

List of attributes associated with this attribute group. Instance type L<W3C::XMLSchema::Attribute>.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
