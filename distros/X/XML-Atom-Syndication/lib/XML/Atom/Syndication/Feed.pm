package XML::Atom::Syndication::Feed;
use strict;

use base qw( XML::Atom::Syndication::Thing );

use XML::Atom::Syndication::Util qw( nodelist );

XML::Atom::Syndication::Feed->mk_accessors('element', 'icon', 'logo');
XML::Atom::Syndication::Feed->mk_accessors('XML::Atom::Syndication::Generator',
                                           'generator');
XML::Atom::Syndication::Feed->mk_accessors('XML::Atom::Syndication::Text',
                                           'subtitle');

# deprecated 0.3 accessors
XML::Atom::Syndication::Feed->mk_accessors('attribute', 'version');
XML::Atom::Syndication::Feed->mk_accessors('element', 'copyright', 'modified',
                                           'created');
XML::Atom::Syndication::Feed->mk_accessors('XML::Atom::Syndication::Text',
                                           'tagline', 'info');

sub element_name { 'feed' }

sub add_entry {
    my ($feed, $entry) = @_;
    $entry = $entry->elem if ref $entry eq 'XML::Atom::Syndication::Entry';
    $feed->set_element($feed->ns, 'entry', $entry, 1);
}

sub insert_entry {
    my ($feed, $entry) = @_;
    $entry = $entry->elem if ref $entry eq 'XML::Atom::Syndication::Entry';
    my ($first) = nodelist($feed, $feed->ns, 'entry');
    if ($first) {
        my $e = $feed->elem;
        $entry->parent($e);
        my @new =
          map { $_ eq $first ? ($entry, $_) : $_ } @{$e->contents};
        $e->contents(\@new);
    } else {
        $feed->set_element($feed->ns, 'entry', $entry, 1);
    }
}

sub entries {    # why? because read_only????
    my $feed = shift;
    my @nodes = nodelist($feed, $feed->ns, 'entry');
    return unless @nodes;
    my @entries;
    require XML::Atom::Syndication::Entry;
    foreach my $node (@nodes) {
        my $entry =
          XML::Atom::Syndication::Entry->new(Elem      => $node,
                                             Namespace => $feed->ns);
        push @entries, $entry;
    }
    @entries;
}

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Feed - class representing an Atom feed

=head1 SYNOPSIS

    use XML::Atom::Syndication::Feed;
    use XML::Atom::Syndication::Entry;
    use XML::Atom::Syndication::Text;
    use XML::Atom::Syndication::Content;
    
    # create a feed
    my $feed = XML::Atom::Syndication::Feed->new;
    $feed->title('My Weblog');
    my $entry = XML::Atom::Syndication::Entry->new;
    my $title = XML::Atom::Syndication::Text->new(Name=>'title');
    $title->body('First Post');
    $entry->title($title);
    my $content = XML::Atom::Syndication::Content->new('Post Body');
    $entry->content($content);
    $feed->add_entry($entry);
    $feed->insert_entry($entry);
    print $feed->as_xml;
    
    # list entry titles of index.atom file
    my $feed2 = XML::Atom::Syndication::Feed->new('index.atom');
    my @entries = $feed->entries;
    print $_->title->body."\n" for @entries;

=head1 DESCRIPTION

XML::Atom::Syndication::Feed element is the document (i.e.,
top-level) element of an Atom Feed Document, acting as a
container for metadata and data associated with the feed.
Its element children consist of metadata elements followed
by zero or more entry child elements.

=head1 METHODS

XML::Atom::Syndication::Feed is a subclass of
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
the child Atom elements of the feed with a string.
The string must also be well-formed XML. This
method will replaces any existing child elements.
All elements are presumed to be in the same Atom
namespace as the feed object.

This method is similar to the innerHTML property
found in JavaScript.

=item author

Indicates the author of the feed.

This accessor returns a L<XML::Atom::Syndication::Person>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item category

Conveys information about a category associated with an feed.

This accessor returns a L<XML::Atom::Syndication::Category>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item contributor

Indicates a person or other entity who contributed to the
feed.

This accessor returns a L<XML::Atom::Syndication::Person>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item generator

Identifies the agent used to generate a feed for debugging
and other purposes. 

This accessor returns a L<XML::Atom::Syndication::Generator>
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

This accessor returns a L<XML::Atom::Syndication::Link>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item logo

An IRI reference [RFC3987] which identifies an image which
provides visual identification for a feed.

This accessor returns a string. You can set this attribute
by passing in an optional string.

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

=item subtitle

Conveys a human-readable description or subtitle of a feed.

This accessor returns a L<XML::Atom::Syndication::Text>
object. This element can be set using a string and hash
reference or by passing in an object. See Working with
Object Setters in L<XML::Atom::Syndication::Object> for more
detail.

=item title

Conveys a human-readable title for a feed.

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

=head2 ENTRIES

=over

=item $feed->add_entry($entry)

Appends a L<XML::Atom::Syndication::Entry> object to the
feed. The new entry is placed after all existing entries in
the feed

=item $feed->insert_entry($entry)

Inserts a L<XML::Atom::Syndication::Entry> object I<before>
all other existing entries in the feed.

=item $feed->entries

Returns an ordered ARRAY of L<XML::Atom::Syndication::Entry> objects 
representing the feed's entries.

=back

=head2 DEPRECATED

=over

=item copyright

This element was renamed C<rights> in version 1.0 of the format.

=item created

This element was removed from version 1.0 of the format.

=item info

This element was removed from version 1.0 of the format.

=item modified

This element was renamed C<updated> in version 1.0 of the format.

=item tagline

This element was renamed C<subtitle> in version 1.0 of the format.

=item version

This attribute was removed from version 1.0 of the format.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
