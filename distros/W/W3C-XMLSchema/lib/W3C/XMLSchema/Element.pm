use strict;
use warnings;

package W3C::XMLSchema::Element;
{
  $W3C::XMLSchema::Element::VERSION = '0.0.4';
}
use XML::Rabbit;

# ABSTRACT: XMLSchema Element Definition


has_xpath_value 'name' => './@name';


has_xpath_value 'type' => './@type';


has_xpath_value 'ref' => './@ref';


has_xpath_value 'minOccurs' => './@minOccurs';


has_xpath_value 'maxOccurs' => './@maxOccurs';

finalize_class();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

W3C::XMLSchema::Element - XMLSchema Element Definition

=head1 VERSION

version 0.0.4

=head1 DESCRIPTION

Element, as defined by XMLSchema definition.

See L<W3C::XMLSchema> for a more complete example.

=head1 ATTRIBUTES

=head2 name

Name given to attribute.

=head2 type

Type given of attribute.

=head2 ref

Identifier of the element this element refers to.

=head2 minOccurs

Minimum amount of occurences.

=head2 maxOccurs

Maximum amount of occurences. 'unbounded' means no upper limit.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
