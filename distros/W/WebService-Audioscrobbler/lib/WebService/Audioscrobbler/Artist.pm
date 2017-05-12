package WebService::Audioscrobbler::Artist;
use warnings;
use strict;
use CLASS;

use base 'WebService::Audioscrobbler::Base';

=head1 NAME

WebService::Audioscrobbler::Artist - An object-oriented interface to the Audioscrobbler WebService API

=cut

our $VERSION = '0.08';

# postfix related accessors
CLASS->mk_classaccessor("base_resource_path"  => "artist");

# similar artists related accessors
CLASS->mk_classaccessor("similar_artists_postfix" => "similar.xml");
CLASS->mk_classaccessor("similar_artists_class"   => "WebService::Audioscrobbler::SimilarArtist");

# change the field used to sort stuff
CLASS->tracks_sort_field('reach');

# requiring stuff
CLASS->similar_artists_class->require or die($@);
CLASS->tracks_class->require          or die($@);
CLASS->tags_class->require            or die($@);

# object accessors
CLASS->mk_accessors(qw/name mbid streamable picture_url/);

=head1 SYNOPSIS

This module implements an object oriented abstraction of an artist within the
Audioscrobbler database.

    use WebService::Audioscrobbler;

    my $ws = WebService::Audioscrobbler->new;

    # get an object for artist named 'foo'
    my $artist  = $ws->artist('foo');

    # fetch artists similar to 'foo'
    my @similar = $artist->similar_artists;

    print "Artists similar to: " . $artist->name . "\n";

    # prints each one of their names
    for my $similar (@similar) {
        print $similar->name . "\n";
    }

    # retrieves tracks from 'foo'
    my @tracks = $artist->tracks;

    # retrieves tags associated with 'foo'
    my @tags = $artist->tags;

This module inherits from L<WebService::Audioscrobbler::Base>.

=head1 FIELDS

=head2 C<name>

The name of a given artist as provided when constructing the object.

=head2 C<mbid>

MusicBrainz ID as provided by the Audioscrobbler database.

=head2 C<picture_url>

URI object pointing to the location of the artist's picture, if available.

=head2 C<streamable>

Flag indicating whether the artist has streamable content available.

=cut

=head1 METHODS

=cut

=head2 C<new($artist_name, $data_fetcher)>

=head2 C<new(\%fields)>

Creates a new object using either the given C<$artist_name> or the C<\%fields> 
hashref. The data fetcher object is a mandatory parameter and must
be provided either as the second parameter or inside the C<\%fields> hashref. 

=cut

sub new {
    my $class = shift;
    my ($name_or_fields, $data_fetcher) = @_;

    my $self = $class->SUPER::new( 
        ref $name_or_fields eq 'HASH' ? 
            $name_or_fields : { name => $name_or_fields, data_fetcher => $data_fetcher } 
    );

    $self->croak("No data fetcher provided")
        unless $self->data_fetcher;

    unless (defined $self->name) {
        if (defined $self->{content}) {
            $self->name($self->{content});
        }
        else {
            $class->croak("Can't create artist without a name");
        }
    }

    return $self;
}

=head2 C<similar_artists([$filter])>

=head2 C<related_artists([$filter])>

=head2 C<artists([$filter])>

Retrieves similar artists from the Audioscrobbler database. $filter can be used
to limit artist with a low similarity index (ie. artists which have a similarity
index lower than $filter won't be returned).

Returns either a list of artists or a reference to an array of artists when called 
in list context or scalar context, respectively. The artists are returned as 
L<WebService::Audioscrobbler::SimilarArtist> objects by default.

=cut

*related_artists = *artists = \&similar_artists;

sub similar_artists {
    my $self = shift;
    my $filter = shift || 1;

    my $data = $self->fetch_data($self->similar_artists_postfix);
    
    $self->load_fields($data);

    my @artists;

    # check if we've got any similar artists
    if (ref $data->{artist} eq 'ARRAY') {

        shift @{$data->{artist}};

        @artists = map {
            my $artist = $_;
            $self->similar_artists_class->new({
                picture_url  => URI->new($_->{image}),
                related_to   => $self,
                data_fetcher => $self->data_fetcher,
                map {$_ => $artist->{$_}} qw/name streamable mbid match/
            })
        } grep { $_->{match} >= $filter } @{$data->{artist}};

    }

    return wantarray ? @artists : \@artists;
}

=head2 C<tracks>

Retrieves the artist's top tracks as available on Audioscrobbler's database.

Returns either a list of tracks or a reference to an array of tracks when called 
in list context or scalar context, respectively. The tracks are returned as 
L<WebService::Audioscrobbler::Track> objects by default.

=cut

=head2 C<tags>

Retrieves the artist's top tags as available on Audioscrobbler's database.

Returns either a list of tags or a reference to an array of tags when called 
in list context or scalar context, respectively. The tags are returned as 
L<WebService::Audioscrobbler::Tag> objects by default.

=cut

=head2 C<load_fields(\%data)>

Loads artist fields from the hashref C<\%data>.

=cut

sub load_fields {
    my $self = shift;
    my $data = shift;

    $self->streamable($data->{streamable});

    $self->picture_url(URI->new($data->{picture}))
        unless $self->picture_url;
    
    $self->mbid($data->{mbid}) 
        unless $self->mbid;
}

=head2 C<resource_path>

Returns the URL from which other URLs used for fetching artist info will be 
derived from.

=cut

sub resource_path {
    my $self = shift;
    $self->uri_builder( $self->name );
}

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Audioscrobbler::Artist
