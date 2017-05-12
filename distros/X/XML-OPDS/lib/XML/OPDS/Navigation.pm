package XML::OPDS::Navigation;

use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str Enum Bool InstanceOf Object/;
use Moo;
use DateTime;
use XML::Atom::Link;

=head1 NAME

XML::OPDS::Navigation - Navigation elements for OPDS feeds

=head1 SETTERS/ACCESSORS

The all are read-write

=head2 prefix

If provided, every uri will have this string prepended, so you can
just pass URIs like '/path/to/file' and have them consistently turned
to 'http://myserver.org/path/to/file' if you set this to
'http://myserver.org'. See also L<XML::OPDS> C<prefix> method.

=head2 href

Required. The URI of the resource. If prefix is provided it is
prepended on output.

=head2 id

=head2 rel

Defaults to C<subsection>. Permitted values: C<self>, C<start>, C<up>,
C<subsection>, C<search>.

Additionally:

C<new> and C<popular> will expand to L<http://opds-spec.org/sort/new> and
L<http://opds-spec.org/sort/popular> as per spec paragraph 7.4.1.

Acquisition Feeds using the "http://opds-spec.org/sort/new" relation SHOULD be
ordered with the most recent items first. Acquisition Feeds using the "
http://opds-spec.org/sort/popular" relation SHOULD be ordered with the most
popular items first.

C<featured> will expand to L<http://opds-spec.org/featured> as per 7.4.2

C<recommended> will expand to L<http://opds-spec.org/recommended> as per 7.4.3

C<shelf> will expand to L<http://opds-spec.org/shelf> and
C<subscriptions> to L<http://opds-spec.org/subscriptions>.

C<crawlable> will expand to L<http://opds-spec.org/crawlable>.

This list is a work in progress and probably incomplete.

Facets are not supported yet (patches welcome). Client support for
facets is unclear. L<https://en.wikipedia.org/wiki/OPDS>.

=head2 title

=head2 acquistion

Boolean, default to false. Indicates that the C<href> is a leaf feed
with acquisition entries.

=head2 description

HTML allowed.

=head2  updated

A L<DateTime> object with the time of last update.

=head2 prefix



=cut

has id => (is => 'rw', isa => Str);

has rel => (is => 'rw',
            isa => Enum[qw/self start up subsection search/,
                        qw/first last previous next/, # RFC 5005
                        keys(%{ +{ __PACKAGE__->_rel_map } })],
            default => sub { 'subsection' });

has title => (is => 'rw', isa => Str);

has href => (is => 'rw', isa => Str, required => 1);

has acquisition => (is => 'rw', isa => Bool, default => sub { 0 });

has description => (is => 'rw', isa => Str);

has updated => (is => 'rw', isa => InstanceOf['DateTime'],
                default => sub { return DateTime->now });

has prefix => (is => 'rw', isa => Str, default => sub { '' });

has _dt_formatter => (is => 'ro', isa => Object, default => sub { DateTime::Format::RFC3339->new });

=head1 METHODS

The are mostly internals and used by L<XML::OPDS>

=head2 link_type

Depend if C<acquisition> is true of false.

=head2 as_link

The navigation as L<XML::Atom::Link> object.

=head2 identifier

Return the id or the URI.

=head2 relationship

[INTERNAL] Resolve the rel shortcuts.

=head2 as_entry

The navigation as L<XML::Atom::Entry> object.

=cut

sub link_type {
    my $self = shift;
    if ($self->rel eq 'search') {
        return "application/opensearchdescription+xml";
    }
    my $kind = $self->acquisition ? 'acquisition' : 'navigation';
    return "application/atom+xml;profile=opds-catalog;kind=$kind";
}

sub _rel_map {
    my %map = (
               new => "http://opds-spec.org/sort/new",
               popular => "http://opds-spec.org/sort/popular",
               featured => "http://opds-spec.org/featured",
               recommended => "http://opds-spec.org/recommended",
               shelf => "http://opds-spec.org/shelf",
               subscriptions => "http://opds-spec.org/subscriptions",
               crawlable => "http://opds-spec.org/crawlable",
              );
}

sub relationship {
    my $self = shift;
    my %mapped = $self->_rel_map;
    my $rel = $self->rel;
    return $mapped{$rel} || $rel;
}

sub as_link {
    my $self = shift;
    my $link = XML::Atom::Link->new(Version => 1.0);
    $link->rel($self->relationship);
    $link->href($self->prefix . $self->href);
    $link->type($self->link_type);
    if (my $title = $self->title) {
        $link->title($title);
    }
    return $link;
}

sub identifier {
    my $self = shift;
    return $self->id || $self->prefix . $self->href;
}

sub as_entry {
    my $self = shift;
    my $item = XML::Atom::Entry->new(Version => 1.0);
    $item->title($self->title);
    $item->id($self->identifier);
    $item->content($self->description);
    $item->updated($self->_dt_formatter->format_datetime($self->updated));
    $item->add_link($self->as_link);
    return $item;
}

1;
