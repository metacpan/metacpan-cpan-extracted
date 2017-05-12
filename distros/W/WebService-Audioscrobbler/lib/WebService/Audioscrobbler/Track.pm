package WebService::Audioscrobbler::Track;
use warnings;
use strict;
use CLASS;

use base 'WebService::Audioscrobbler::Base';

=head1 NAME

WebService::Audioscrobbler::Track - An object-oriented interface to the Audioscrobbler WebService API

=cut

our $VERSION = '0.08';

# postfix related accessors
CLASS->mk_classaccessor("base_resource_path"  => "track");

# requiring stuff
CLASS->tags_class->require or die($@);

# object accessors
CLASS->mk_accessors(qw/artist name mbid url streamable/);

*title = \&name;

=head1 SYNOPSIS

This module implements an object oriented abstraction of a track within the
Audioscrobbler database.

    use WebService::Audioscrobbler::Track;

    my $ws = WebService::Audioscrobbler->new;
    
    # get a track object for the track titled 'bar' by 'foo'
    my $track = $ws->track('foo', 'bar');

    # retrieves the track's tags
    my @tags = $track->tags;

    # prints url for viewing aditional tag info
    print $track->url;

    # prints the tag's artist name
    print $track->artist->name;

This module inherits from L<WebService::Audioscrobbler::Base>.

=head1 FIELDS

=head2 C<artist>

The track's performing artist.

=head2 C<name>
=head2 C<title>

The name (title) of a given track.

=head2 C<mbid>

MusicBrainz ID as provided by the Audioscrobbler database.

=head2 C<url>

URL for aditional info about the track.

=cut

=head1 METHODS

=cut

=head2 C<new($artist, $title, $data_fetcher)>

=head2 C<new(\%fields)>

Creates a new object using either the given C<$artist> and C<$title> or the 
C<\%fields> hashref. The data fetcher object is a mandatory parameter and must
be provided either as the second parameter or inside the C<\%fields> hashref.

=cut

sub new {
    my $class = shift;
    my ($artist_or_fields, $title, $data_fetcher) = @_;

    my $self = $class->SUPER::new( 
        ref $artist_or_fields eq 'HASH' ? 
            $artist_or_fields : { artist => $artist_or_fields, name => $title, data_fetcher => $data_fetcher } 
    );

    $class->croak("No data fetcher provided")
        unless $self->data_fetcher;

    return $self;
}

=head2 C<tags>

Retrieves the track's top tags as available on Audioscrobbler's database.

Returns either a list of tags or a reference to an array of tags when called 
in list context or scalar context, respectively. The tags are returned as 
L<WebService::Audioscrobbler::Tag> objects by default.

=cut

sub tracks {
    shift->croak("Audioscrobbler doesn't provide data regarding tracks which are related to other tracks");
}

sub artists {
    shift->croak("Audioscrobbler doesn't provide data regarding artists related to specific tracks");
}

=head2 C<resource_path>

Returns the URL from which other URLs used for fetching track info will be 
derived from.

=cut

sub resource_path {
    my $self = shift;
    $self->uri_builder( $self->artist->name, $self->name );
}

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Audioscrobbler::Track
