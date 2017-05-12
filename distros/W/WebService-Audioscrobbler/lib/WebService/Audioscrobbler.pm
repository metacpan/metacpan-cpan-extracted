package WebService::Audioscrobbler;
use warnings;
use strict;
use CLASS;

use base 'Class::Data::Accessor';
use base 'Class::Accessor::Fast';

use NEXT;
use UNIVERSAL::require;

use URI;

=head1 NAME

WebService::Audioscrobbler - An object-oriented interface to the Audioscrobbler WebService API

=cut

our $VERSION = '0.08';

CLASS->mk_classaccessor("base_url" => URI->new("http://ws.audioscrobbler.com/1.0/"));

# defining default classes
CLASS->mk_classaccessor("artist_class"       => CLASS . '::Artist');
CLASS->mk_classaccessor("track_class"        => CLASS . '::Track');
CLASS->mk_classaccessor("tag_class"          => CLASS . '::Tag');
CLASS->mk_classaccessor("user_class"         => CLASS . '::User');
CLASS->mk_classaccessor("data_fetcher_class" => CLASS . '::DataFetcher');

# requiring stuff
CLASS->artist_class->require         or die $@;
CLASS->track_class->require          or die $@;
CLASS->tag_class->require            or die $@;
CLASS->user_class->require           or die $@;
CLASS->data_fetcher_class->require   or die $@;

# object accessors
CLASS->mk_accessors(qw/data_fetcher/);

=head1 SYNOPSIS

B<WARNING: This module UNMAINTAINED and broken at this point in time.>
B<It doesn't work anymore as the APIs used were taken offline.>
If you feel like taking over and developing it further, feel free to contact the
author.

Thisa module aims to be a full implementation of a an object-oriented interface 
to the Audioscrobbler WebService API (as available on 
L<http://www.audioscrobbler.net/data/webservices/>). Since version 0.04, the 
module fully supports data caching and, thus, complies to the service's 
recommended usage guides.

    use WebService::Audioscrobbler;

    my $ws = WebService::Audioscrobbler->new;

    # get an object for artist named 'foo'
    my $artist  = $ws->artist('foo');

    # retrieves tracks from 'foo'
    my @tracks = $artist->tracks;

    # retrieves tags associated with 'foo'
    my @tags = $artist->tags;

    # fetch artists similar to 'foo'
    my @similar = $artist->similar_artists;

    # prints each one of their names
    for my $similar (@similar) {
        print $similar->name . "\n";
    }

    ...

    # get an object for tag 'bar'
    my $tag = $ws->tag('bar');

    # fetch tracks tagged with 'bar'
    my @bar_tracks = $tag->tracks;

    ...

    my $user = $ws->user('baz');

    my @baz_neighbours = $user->neighbours;

Audioscrobbler is a great service for tracking musical data of various sorts,
and its integration with the LastFM service (L<http://www.last.fm>) makes it
work even better. Audioscrobbler provides data regarding similarity between
artists, artists discography, tracks by musical genre (actually, by tags), 
top artists / tracks / albums / tags and how all of that related to your own
musical taste.

Currently, only of subset of these data feeds are implemented, which can be 
viewed as the core part of the service: artists, tags, tracks and users. Since 
this module was developed as part of a automatic playlist building application 
(still in development) these functions were more than enough for its initial 
purposes but a (nearly) full WebServices API is planned. 

In any case, code or documentation patches are welcome.

=head1 METHODS

=cut

=head2 C<new([$cache_root]>

Creates a new C<WebService::Audioscrobbler> object. This object can then be 
used to retrieve various bits of information from the Audioscrobbler database. 
If C<$cache_root> is specified, Audioscrobbler data will be cached under this 
directory, otherwise it will use L<Cache::FileCache> defaults.

=cut

sub new {
    my $class = shift;
    my ($cache_root) = @_;

    my $self = bless {}, $class;
    
    # creates the data fetcher object which will be extensively used
    $self->data_fetcher( 
        $self->data_fetcher_class->new( {
            base_url    =>  $self->base_url,
            cache_root  =>  $cache_root
        } )
    );

    $self;
}

=head2 C<artist($name)>

Returns an L<WebService::Audioscrobbler::Artist> object constructed using the 
given C<$name>. Note that this call doesn't actually check if the artist exists
since no remote calls are dispatched - the object is only constructed.

=cut

sub artist {
    my ($self, $artist) = @_;
    return $self->artist_class->new($artist, $self->data_fetcher);
}

=head2 C<track($artist, $title)>

Returns an L<WebService::Audioscrobbler::Track> object constructed used the 
given C<$artist> and C<$title>. The C<$artist> parameter can either be a 
L<WebService::Audioscrobbler::Artist> object or a string (in this case, a 
L<WebService::Audioscrobbler::Artist> will be created behind the scenes). Note 
that this call doesn't actually check if the track exists since no remote calls
are dispatched - the object is only constructed.

=cut

sub track {
    my ($self, $artist, $title) = @_;

    $artist = $self->artist($artist) 
        unless ref $artist; # assume the user knows what he's doing

    return $self->track_class->new($artist, $title, $self->data_fetcher);
}

=head2 C<tag($name)>

Returns an L<WebService::Audioscrobbler::Tag> object constructed using the given
C<$name>. Note that this call doesn't actually check if the tag exists since no
remote calls are dispatched - the object is only constructed.

=cut

sub tag {
    my ($self, $tag) = @_;
    return $self->tag_class->new($tag, $self->data_fetcher);
}

=head2 C<user($name)>

Returns an L<WebService::Audioscrobbler::User> object constructed using the given
C<$name>. Note that this call doesn't actually check if the user exists since no
remote calls are dispatched - the object is only constructed.

=cut

sub user {
    my ($self, $user) = @_;
    return $self->user_class->new($user, $self->data_fetcher);
}

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-audioscrobbler at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Audioscrobbler>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Audioscrobbler

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Audioscrobbler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Audioscrobbler>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Audioscrobbler>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Audioscrobbler>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

B<NOTE>: The datafeed from audioscrobbler.net is for
I<non-commercial use only>. Please see 
L<http://www.audioscrobbler.net/data/webservices/> for
more licensing information.

=head1 SEE ALSO

=over 4

=item * L<http://www.audioscrobbler.net/data/webservices/> and L<http://www.last.fm/>

=item * L<WebService::LastFM::SimilarArtists>, L<WebServices::LastFM>, L<Audio::Scrobbler>

=item * L<LWP::Simple>, L<XML::Simple>, L<Cache::FileCache>, L<URI>

=back

=cut

1; # End of WebService::Audioscrobbler
