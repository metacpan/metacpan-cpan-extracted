package XML::OPDS::Acquisition;

use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str ArrayRef InstanceOf Object/;
use Moo;
use DateTime;
use XML::Atom;
use XML::Atom::Person;
use XML::Atom::Entry;

=head1 NAME

XML::OPDS::Acquisition - Acquisition elements for OPDS feeds

=head1 SETTERS/ACCESSORS

The following accessors are read-only and are meant to be passed as an
hash to the C<new> constructor.

=head2 id

Optional. The example specification uses uuid like
C<urn:uuid:2853dacf-ed79-42f5-8e8a-a7bb3d1ae6a2>. If not provided, the
C<href> (with the prefix if provided) will be used instead.

=head2 prefix

If provided, every uri will have this string prepended, so you can
just pass URIs like '/path/to/file' and have them consistently turned
to 'http://myserver.org/path/to/file' if you set this to
'http://myserver.org'. See also L<XML::OPDS> C<prefix> method.

=cut

has id => (is => 'ro', isa => Str);

has prefix => (is => 'ro', isa => Str, default => sub { '' });

=head2 href

The URI of the resource. Required.

=cut

has href => (is => 'ro', isa => Str, required => 1);

=head2 title

The title. Required.

=cut

has title => (is => 'ro', isa => Str, required => 1);

=head2 files

An arrayref with the download files. The prefix is added if set.

=head1 OPTIONAL ATTRIBUTES

The following attributes are optional and describe the publication.

=head2 authors

An arrayref of either scalars with names, or hashrefs with C<name> and
C<uri> as keys. C<uri> is optional.

=head2 summary

Plain text.

=head2 description

HTML allowed.

=head2 language

=head2 issued

The publication date.

=head2 publisher

=head2 updated

A DateTime object with the time of the last update of the resource.

=cut

has authors => (is => 'ro', isa => ArrayRef);

has summary => (is => 'ro', isa => Str);

has description => (is => 'ro', isa => Str);

has language => (is => 'ro', isa => Str);

has issued => (is => 'ro', isa => Str);

has publisher => (is => 'ro', isa => Str);

has updated => (is => 'rw', isa => InstanceOf['DateTime'],
                default => sub { return DateTime->now });

has files => (is => 'ro', isa => ArrayRef[Str], default => sub { [] });

has _dt_formatter => (is => 'ro', isa => Object, default => sub { DateTime::Format::RFC3339->new });

=head2 thumbnail

The uri of the thumbnail

=head2 image

The uri of the image

=head1 METHODS

Usually they are for internal usage.

=head2 identifier

=head2 authors_as_links

Return a list of L<XML::Atom::Person> objects from the C<authors>
value.

=head2 files_as_links

Return a list of L<XML::Atom::Link> objects constructed from C<files>,
C<image>, C<thumbnail>, with the appropriate C<rel> and C<type>.

=head2 as_entry

Return the acquisition L<XML::Atom::Entry> object.

=cut

has thumbnail => (is => 'ro', isa => Str);

has image => (is => 'ro', isa => Str);

has _dc => (is => 'lazy',
            isa => Object,
            default => sub {
                XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
            });

sub identifier {
    my $self = shift;
    return $self->id || $self->prefix . $self->href;
}

sub authors_as_links {
    my $self = shift;
    my @out;
    if (my $authors = $self->authors) {
        foreach my $author (@$authors) {
            my $hash = ref($author) ? $author : { name => $author };
            if (my $name = $hash->{name}) {
                my $author_obj = XML::Atom::Person->new(Version => 1.0);
                $author_obj->name($hash->{name});
                if (my $uri = $hash->{uri}) {
                    $author_obj->uri($self->prefix . $uri);
                }
                push @out,  $author_obj;
            }
        }
    }
    return @out;
}

sub files_as_links {
    my $self = shift;
    my @out;
    my %mime = (
                tex => 'application/x-tex',
                pdf => 'application/pdf',
                html => 'text/html',
                epub => 'application/epub+zip',
                muse => 'text/plain',
                txt => 'text/plain',
                zip => 'application/zip',
                png => 'image/png',
                jpg => 'image/jpeg',
                jpeg => 'image/jpeg',
                gif => 'image/gif',
                mobi => 'application/x-mobipocket-ebook',
               );
    # maybe support open-access, borrow, buy, sample, subscribe ? 8.4.1
    my @all = map { +{ rel => 'acquisition', href => $_ } } @{$self->files};
    die "Missing acquisition links" unless @all;

    if (my $thumb = $self->thumbnail) {
        push @all, { rel => 'image/thumbnail', href => $thumb };
    }
    if (my $image = $self->image) {
        push @all, { rel => 'image', href => $image };
    }
    foreach my $file (@all) {
        my $mime_type;
        if ($file->{href} =~ m/\.(\w+)\z/) {
            my $ext = $1;
            $mime_type = $mime{$ext};
        }
        next unless $mime_type;
        my $link = XML::Atom::Link->new(Version => 1.0);
        $link->rel("http://opds-spec.org/$file->{rel}");
        $link->href($self->prefix . $file->{href});
        $link->type($mime_type);
        push @out, $link;
    }
    if (@out) {
        return @out;
    }
    else {
        die "Links are required"
    };
}

sub as_entry {
    my $self = shift;
    my $entry = XML::Atom::Entry->new(Version => 1.0);
    $entry->id($self->identifier);
    $entry->title($self->title);
    $entry->updated($self->_dt_formatter->format_datetime($self->updated));
    if (my $lang = $self->language) {
        $entry->set($self->_dc, language => $lang);
    }
    foreach my $author ($self->authors_as_links) {
        $entry->add_author($author);
    }
    if (my $summary = $self->summary) {
        $entry->summary($summary);
    }
    if (my $desc = $self->description) {
        $entry->content($desc);
    }
    foreach my $link ($self->files_as_links) {
        $entry->add_link($link);
    }
    return $entry;
}

1;
