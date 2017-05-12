package XML::Atom::Syndication::Category;
use strict;

use base qw( XML::Atom::Syndication::Object );

XML::Atom::Syndication::Category->mk_accessors('attribute', 'term', 'scheme',
                                               'label');

sub element_name { 'category' }

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Category - class representing an Atom category

=head1 DESCRIPTION

Conveys information about a category associated with an
entry or feed. This specification assigns no meaning to the
content (if any) of this element.

=head1 METHODS

XML::Atom::Syndication::Category is a subclass of
L<XML::Atom::Syndication:::Object> that it inherits a number of
methods from. You should already be familiar with this base
class before proceeding.

All of these accessors return a string. You can set these attributes
by passing in an optional string.

=over 

=item label

A human-readable label for display in end-user applications.

=item term

A string that identifies the category to which the entry or
feed belongs. This attribute is requires of all category
elements.

=item scheme

An IRI that identifies a categorization scheme.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
