package XML::Atom::Syndication::Entry;
use strict;

use base qw( XML::Atom::Syndication::Thing );

XML::Atom::Syndication::Entry->mk_accessors('XML::Atom::Syndication::Source',
                                            'source');
XML::Atom::Syndication::Entry->mk_accessors('XML::Atom::Syndication::Content',
                                            'content');
XML::Atom::Syndication::Entry->mk_accessors('XML::Atom::Syndication::Text',
                                            'summary');
XML::Atom::Syndication::Entry->mk_accessors('element', 'published');

# deprecated 0.3 accessors
XML::Atom::Syndication::Entry->mk_accessors('element', 'issued', 'modified',
                                            'created');

sub element_name { 'entry' }

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Entry - class representing an Atom entry

=head1 SYNOPSIS

    use XML::Atom::Syndication::Entry;
    use XML::Atom::Syndication::Text;
    use XML::Atom::Syndication::Content;
    
    # create an entry
    my $entry = XML::Atom::Syndication::Entry->new;
    my $title = XML::Atom::Syndication::Text->new(Name=>'title');
    $title->body('First Post');
    $entry->title($title);
    my $content = XML::Atom::Syndication::Content->new('Post Body');
    $entry->content($content);
    print $entry->as_xml;
    
    my $e = XML::Atom::Syndication::Entry->new('entry.atom');
    print $e->title->body."\n";
    
=head1 DESCRIPTION

XML::Atom::Syndication::Entry element represents an
individual Atom entry that acts as a container for metadata
and data associated with the entry. This element can appear
as a child of a feed element represented by
L<XML::Atom::Syndication::Feed>, or it can appear as the
document (i.e., top-level) element of a standalone Atom
Entry Document.

=head1 METHODS

XML::Atom::Syndication::Entry is a subclass of
L<XML::Atom::Syndication::Object> (via
L<XML::Atom::Syndication:::Thing>) that it inherits numerous
methods from. You should already be familiar with this base
class before proceeding.

=over

=item Class->new(%params)

In addition to the keys recognized by its superclass
(L<XML::Atom::Syndication::Object>) this class recognizes a
C<Stream> element. The value of this element can be a SCALAR
or FILEHANDLE (GLOB) to a valid Atom document. The C<Stream>
element takes precedence over the standard C<Elem> element.

=item inner_atom($atom_markup_string)

This is a convenience method for quickly setting
the child Atom elements of the entry with a string.
The string must also be well-formed XML. This
method will replaces any existing child elements.
All elements are presumed to be in the same Atom
namespace as the entry object.

This method is similar to the innerHTML property
found in JavaScript.

=item author

Indicates the author of the entry.

This accessor returns a L<XML::Atom::Syndication::Person>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item category

Conveys information about a category associated with an entry.

This accessor returns a L<XML::Atom::Syndication::Category>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item content

Contains or links to the content of the entry. 

This accessor returns a L<XML::Atom::Syndication::Content>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item contributor

Indicates a person or other entity who contributed to the
entry.

This accessor returns a L<XML::Atom::Syndication::Person>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item id

A permanent, universally unique identifier for an entry or
feed.

This accessor returns a string. You can set this attribute
by passing in an optional string.

=item link

Defines a reference from an entry to a Web resource.

This accessor returns a L<XML::Atom::Syndication::Link>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item published

A date indicating an instance in time associated with an
event early in the life of the entry.

This accessor returns a string. You can set this attribute
by passing in an optional string. Dates values MUST conform
to the "date-time" production in [RFC3339].

=item rights

Conveys information about rights held in and over an entry
or feed.

This accessor returns a L<XML::Atom::Syndication::Text>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item source

Contains meta data describing the original source of the
entry. 

This accessor returns a L<XML::Atom::Syndication::Source>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item summary

Conveys a short summary, abstract, or excerpt of an entry.

This accessor returns a L<XML::Atom::Syndication::Text>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item title

Conveys a human-readable title for an entry.

This accessor returns a L<XML::Atom::Syndication::Text>
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

=head2 DEPRECATED

=over

=item copyright

This element was renamed C<rights> in version 1.0 of the format.

=item created

This element was removed from version 1.0 of the format.

=item issued

This element was renamed C<published> in version 1.0 of the format.

=item modified

This element was renamed C<updated> in version 1.0 of the format.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
