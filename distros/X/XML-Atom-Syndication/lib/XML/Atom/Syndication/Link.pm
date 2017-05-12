package XML::Atom::Syndication::Link;
use strict;

use base qw( XML::Atom::Syndication::Object );

XML::Atom::Syndication::Link->mk_accessors('attribute',
                                     qw( href rel type hreflang title length ));

sub element_name { 'link' }

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Link - class representing an Atom link

=head1 DESCRIPTION

A link defines a reference from an entry or feed to a Web
resource.

=head1 METHODS

XML::Atom::Syndication::Link is a subclass of
L<XML::Atom::Syndication:::Object> that it inherits a number of
methods from. You should already be familiar with this base
class before proceeding.

All of these accessors return a string. You can set these attributes
by passing in an optional string.

=over 

=item href

The link's IRI. Link elements must have an href attribute.

=item hreflang

The language of the resource pointed to by the href
attribute.

=item length

An advisory length of the linked content in octets; it is a
hint about the content length of the representation returned
when the IRI is dereferenced.

=item rel

Indicates the link relation type. Atom defines five initial
values for the rel attribute: alternate, related, self,
enclosure, via.

=item title

Conveys human-readable information about the link.

=item type

An advisory media type; it is a hint about the type of the
representation that is expected to be returned when the
value of the href attribute is dereferenced.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
