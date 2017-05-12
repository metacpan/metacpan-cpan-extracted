use strict;
use warnings;

package W3C::XMLSchema::Group;
{
  $W3C::XMLSchema::Group::VERSION = '0.0.4';
}
use XML::Rabbit;

# ABSTRACT: XMLSchema Group Definition


has_xpath_value 'name' => './@name';


has_xpath_value 'ref' => './@ref';


has_xpath_object 'sequence' => './xsd:sequence' => 'W3C::XMLSchema::Sequence';

finalize_class();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

W3C::XMLSchema::Group - XMLSchema Group Definition

=head1 VERSION

version 0.0.4

=head1 DESCRIPTION

Groups, as defined by XMLSchema definition.

See L<W3C::XMLSchema> for a more complete example.

=head1 ATTRIBUTES

=head2 name

Name given to group.

=head2 ref

Name of other group this group references.

=head2 sequence

The sequence this group requires. Instance of L<W3C::XMLSchema::Sequence>.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
