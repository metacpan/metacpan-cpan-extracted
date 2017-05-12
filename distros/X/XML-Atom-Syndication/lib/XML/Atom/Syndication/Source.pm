package XML::Atom::Syndication::Source;
use strict;

use base qw( XML::Atom::Syndication::Thing );

XML::Atom::Syndication::Source->mk_accessors('element', 'icon', 'logo');
XML::Atom::Syndication::Source->mk_accessors(
                                            'XML::Atom::Syndication::Generator',
                                            'generator');
XML::Atom::Syndication::Source->mk_accessors('XML::Atom::Syndication::Text',
                                             'subtitle');

sub element_name { 'source' }

# This is the init method in XML::Atom::Syndication::Object. Could do
# better.
sub init {
    my $atom = shift;
    my %param = @_ == 1 ? (Elem => $_[0]) : @_;
    $atom->set_ns(\%param);
    unless ($atom->{elem} = $param{Elem}) {
        require XML::Elemental::Element;
        $atom->{elem} = XML::Elemental::Element->new;
        $atom->{elem}->name('{' . $atom->ns . '}' . $atom->element_name);
    }
    $atom;
}

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Source - class representing an Atom
source element

=head1 DESCRIPTION

If an Atom entry is copied from one feed into another feed,
then the source atom:feed's metadata (all child elements of
atom:feed other than the atom:entry elements) MAY be
preserved within the copied entry by adding an atom:source
child element, if it is not already present in the entry,
and including some or all of the source feed's Metadata
elements as the atom:source element's children. Such
metadata SHOULD be preserved if the source atom:feed
contains any of the child elements atom:author,
atom:contributor, atom:rights, or atom:category and those
child elements are not present in the source atom:entry.

The source element is designed to allow the aggregation
of entries from different feeds while retaining information
about an entry's source feed. For this reason, Atom
Processors which are performing such aggregation SHOULD
include at least the required feed-level Metadata elements
(id, title, and updated) in the source element.

Essentially the source element contains any or all of the
elements that can be found in a feed element except for
published and atom entry elements.

=head1 METHODS

XML::Atom::Syndication::Source is a subclass of
L<XML::Atom::Syndication::Object> (via
L<XML::Atom::Syndication::Thing>) that it inherits
a number of methods from. You should already be
familiar with this base class before proceeding.

=over

=item Class->new(%params);

Constructor. A HASH can be passed to initialize the object. Recognized 
keys are:

=over

=item Elem

A L<XML::Elemental::Element> that will be used as the source for this object. 
This object can be retrieved or set using the C<elem> method.

=item Namespace

A string containing the namespace URI for the element.

=item Version

A SCALAR contain the Atom format version. This hash key can
optionally be used instead of setting the element official
Atom Namespace URIs using the Namespace key. Recognized
values are 1.0 and 0.3. 1.0 is used as the default if
Namespace and Version are not defined.

=back

=item inner_atom($atom_markup_string)

This is a convenience method for quickly setting
the child Atom elements of the source with a string.
The string must also be well-formed XML. This
method will replaces any existing child elements.
All elements are presumed to be in the same Atom
namespace as the source object.

This method is similar to the innerHTML property
found in JavaScript.

=item author

Indicates the author of the source feed.

This accessor returns a <XML::Atom::Syndication::Person>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item category

Conveys information about a category associated with a source feed.

This accessor returns a <XML::Atom::Syndication::Category>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item contributor

Indicates a person or other entity who contributed to the
source feed.

This accessor returns a <XML::Atom::Syndication::Person>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item generator

Identifies the agent used to generate a source feed for debugging
and other purposes. 

This accessor returns a <XML::Atom::Syndication::Generator>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item icon

An IRI reference [RFC3987] which identifies an image which
provides iconic visual identification for a feed.

This accessor returns a string. You can set this attribute
by passing in an optional string.

=item id

A permanent, universally unique identifier for a feed.

This accessor returns a string. You can set this attribute
by passing in an optional string.

=item link

Defines a reference from an entry to a Web resource.

This accessor returns a <XML::Atom::Syndication::Link>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item logo

An IRI reference [RFC3987] which identifies an image which
provides visual identification for a feed.

This accessor returns a string. You can set this attribute
by passing in an optional string.

=item rights

Conveys information about rights held in and over an entry
or feed.

This accessor returns a <XML::Atom::Syndication::Text>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item subtitle

Conveys a human-readable description or subtitle of a source
feed.

This accessor returns a <XML::Atom::Syndication::Text>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item title

Conveys a human-readable title for a source feed.

This accessor returns a <XML::Atom::Syndication::Text>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item updated

The most recent instance in time when an entry or feed was
modified in a way the publisher considers significant. 

This accessor returns a string. You can set this attribute
by passing in an optional string. Dates values MUST conform
to the "date-time" production in [RFC3339].

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
