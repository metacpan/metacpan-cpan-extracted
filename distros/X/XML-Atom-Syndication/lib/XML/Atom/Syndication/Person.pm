package XML::Atom::Syndication::Person;
use strict;

use base qw( XML::Atom::Syndication::Object );

XML::Atom::Syndication::Person->mk_accessors('element', 'name', 'email', 'uri');
XML::Atom::Syndication::Person->mk_accessors('element', 'url')
  ;    # deprecated 0.3 accessors

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Person - class representing an Atom
person construct

=head1 DESCRIPTION

A Person construct is an element that describes a person,
corporation, or similar entity. The person construct is used
to define an author or contributor.

=head1 METHODS

XML::Atom::Syndication::Generator is a subclass of
L<XML::Atom::Syndication:::Object> that it inherits a number of
methods from. You should already be familiar with this base
class before proceeding.

All of these accessors return a string. You can set these elements
by passing in an optional string.

=over

=item name

A human-readable name for the person. A person construct
must contain one name element.

=item uri

An IRI associated with the person.

=item email

An e-mail address associated with the person.

=back

=head2 DEPRECATED

=over 

=item url

This attribute was renamed C<uri> in version 1.0 of the format.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
