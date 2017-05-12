use strict;
use warnings;

package W3C::XMLSchema::Attribute;
{
  $W3C::XMLSchema::Attribute::VERSION = '0.0.4';
}
use XML::Rabbit;

# ABSTRACT: XMLSchema Attribute Definition


has_xpath_value 'name' => './@name';


has_xpath_value 'type' => './@type';


has_xpath_value 'use' => './@use';

finalize_class();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

W3C::XMLSchema::Attribute - XMLSchema Attribute Definition

=head1 VERSION

version 0.0.4

=head1 DESCRIPTION

Attribute, as defined by XMLSchema definition.

See L<W3C::XMLSchema> for a more complete example.

=head1 ATTRIBUTES

=head2 name

Name given to attribute.

=head2 type

Type given of attribute.

=head2 use

If the attribute is required or not. A string with the value 'required' or 'optional';

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
