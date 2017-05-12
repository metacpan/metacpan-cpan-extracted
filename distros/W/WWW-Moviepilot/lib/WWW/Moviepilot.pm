package WWW::Moviepilot;

use warnings;
use strict;

use Carp;
use JSON::Any;
use LWP::UserAgent;
use URI;
use URI::Escape;

use WWW::Moviepilot::Movie;

=head1 NAME

WWW::Moviepilot - Interface to the moviepilot.de database

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use WWW::Moviepilot;
    my $m = WWW::Moviepilot->new({
        api_key => ...,
        host    => 'www.moviepilot.de',
    });

    # direct retrieval
    my $movie = $m->movie( 'matrix' );

    # search
    my @movies = $m->search_movie( 'matrix' );
    foreach my $movie ( @movies ) {
        print $movie->display_title;
    }

    # cast of a movie
    my @cast = $m->cast( 'matrix' );
    foreach my $person ( @cast ) {
        print $person->last_name;
        print $person->character;
    }

    # filmography of a person
    my @filmography = $m->filmography( 'paul-newman' );
    foreach my $movie ( @filmography ) {
        print $movie->display_title;
        print $movie->character;
    }

I<Please note: This module is still in early development and subject to change.>

=head1 METHODS

=head2 new( $args )

Creates a new WWW::Moviepilot instance.

    my $m = WWW::Moviepilot->new( $args );

C<$args> must be a hash reference, you should supply an API key:

    $args->{api_key} = ...;

To get a valid API key you should read L<http://wiki.github.com/moviepilot/moviepilot-API/>.

Further optional arguments:

=over 4

=item * C<host> (default: C<www.moviepilot.de>)

The host where the requests are sent to.

=item * C<ua> (default: C<< LWP::UserAgent->new >>)

A L<LWP::UserAgent> compatible user agent.

=back

=cut

sub new {
    my ($class, $args) = @_;
    my $self = bless {} => $class;
    $self->{api_key} = $args->{api_key} || croak "api_key is missing at " . __PACKAGE__ . "->new()";
    $self->{host}    = $args->{host}    || 'www.moviepilot.de';
    $self->{ua}      = $args->{ua}      || LWP::UserAgent->new;

    $self->{host} = 'http://' . $self->{host} unless $self->{host} =~ m{^http://};

    return $self;
}

=head2 movie( $name ) | movie( $source => $id )

Retrieve a movie as L<WWW::Moviepilot::Movie> object.
There are two ways to specify which movie to retrieve.
First, you can provide the name of the movie (this name is some kind of normalised,
I'm not sure how exactly):

    my $movie = $m->movie( 'matrix' );

The second form is to provide an alternate ID:

    my $movie = $m->movie( imdb => '133093' );
    my $movie = $m->movie( amazon => 'B00004R80K' );

=cut

sub movie {
    my ($self, @args) = @_;

    my $url = $self->host . '/movies/';
    if ( @args > 2 ) {
        croak "invalid usage of " . __PACKAGE__ . "->movie()";
    }
    $url .= join '-id-', map { uri_escape($_) } @args;
    $url .= '.json';

    my $uri = URI->new( $url );
    $uri->query_form( api_key => $self->api_key );
    my $res = $self->ua->get( $uri->as_string );

    if( $res->is_error ) {
        croak $res->status_line;
    }

    my $json = JSON::Any->from_json( $res->decoded_content );

    my $movie = WWW::Moviepilot::Movie->new({ m => $self });
    $movie->populate({ data => { movie => $json } });
    return $movie;
}

=head2 search_movie( $query )

Searches for a movie and returns a list with results:

    my @movielist = $m->search_movie( 'matrix' );
    if ( @movielist == 0 ) {
        print 'no movies found';
    }
    else {
        # each $movie is a WWW::Moviepilot::Movie object
        foreach my $movie ( @movielist ) {
            print $movie->display_title;        # e.g. Matrix
            print $movie->production_year;      # e.g. 1999
            print scalar $movie->emotions_list; # e.g. Spannend,Aufregend

            # in list context, all *_list fields are split up by comma
            my @emotions = $movie->emotions_list;
        }
    }

At most there are 20 movies returned.

See L<WWW::Moviepilot::Movie>.

=cut

sub search_movie {
    my ($self, $query) = @_;

    my $uri = URI->new( $self->host . '/searches/movies.json' );
    $uri->query_form(
        api_key => $self->api_key,
        q       => $query,
    );

    my $res = $self->ua->get( $uri->as_string );
    if ( $res->is_error ) {
        croak $res->status_line;
    }

    my $o = JSON::Any->from_json( $res->decoded_content );

    my @result = ();
    foreach my $entry ( @{ $o->{movies} } ) {
        my $movie = WWW::Moviepilot::Movie->new({ m => $self });
        $movie->populate({ data => { movie => $entry } });
        push @result, $movie;
    }

    return @result;
}

=head2 person( $name )

Retrieve a person as L<WWW::Moviepilot::Person> object.
You should provide the name of the movie (this name is some kind of normalised,
I'm not sure how exactly):

    my $person = $m->person( 'paul-newman' );

=cut

sub person {
    my ($self, $name) = @_;

    my $uri = URI->new( $self->host . '/people/' . uri_escape($name) . '.json' );
    $uri->query_form( api_key => $self->api_key );
    my $res = $self->ua->get( $uri->as_string );

    if( $res->is_error ) {
        croak $res->status_line;
    }

    my $json = JSON::Any->from_json( $res->decoded_content );
    my $person = WWW::Moviepilot::Person->new({ m => $self });
    $person->populate({ data => { person => $json } });
    return $person;
}

=head2 search_person( $query )

Searches for a person and returns a list with results:

    my @people = $m->search_person( 'Paul Newman' );
    if ( @people == 0 ) {
        print 'no people found';
    }
    else {
        # each $person is a WWW::Moviepilot::Person object
        foreach my $person ( @person ) {
            print $person->first_name; # e.g. Paul
            print $person->last_name;  # e.g. Newman
        }
    }

See L<WWW::Moviepilot::Person>.

=cut

sub search_person {
    my ($self, $query) = @_;

    my $uri = URI->new( $self->host . '/searches/people.json' );
    $uri->query_form(
        api_key => $self->api_key,
        q       => $query,
    );

    my $res = $self->ua->get( $uri->as_string );
    if ( $res->is_error ) {
        croak $res->status_line;
    }

    my $o = JSON::Any->from_json( $res->decoded_content );

    my @result = ();
    foreach my $entry ( @{ $o->{people} } ) {
        my $person = WWW::Moviepilot::Person->new({ m => $self });
        $person->populate({ data => { person => $entry } });
        push @result, $person;
    }

    return @result;
}

=head2 cast( $name )

Returns the cast of a movie.

    my $m = WWW::Moviepilot->new(...);
    my @cast = $m->cast('brust-oder-keule');

See L<WWW::Moviepilot::Person>.

=cut

sub cast {
    my ($self, $name) = @_;
    my $movie = WWW::Moviepilot::Movie->new({ m => $self });
    return $movie->cast( $name );
}

=head2 filmography( $name )

Returns the filmography of a person.

    my $m = WWW::Moviepilot->new(...);
    my @filmography = $m->filmography('paul-newman');

See L<WWW::Moviepilot::Movie>.

=cut

sub filmography {
    my ($self, $name) = @_;
    my $person = WWW::Moviepilot::Person->new({ m => $self });
    return $person->filmography( $name );
}

=head2 api_key

    my $api_key = $m->api_key;

Returns the API key provided to the C<new> constructor.

=cut

sub api_key { return shift->{api_key} }

=head2 ua

    my $ua = $m->ua;

Returns the user agent, usually a L<LWP::UserAgent>.

=cut

sub ua { return shift->{ua} }

=head2 host

    my $host = $m->host;

Returns host which the requests are sent to provided to the C<new> constructor.

=cut

sub host { return shift->{host} }

1;
__END__

=head1 SEE ALSO

The Moviepilot API Dokumentation at L<http://wiki.github.com/moviepilot/moviepilot-API/>,
L<WWW::Moviepilot::Movie>, L<WWW::Moviepilot::Person>, L<LWP::UserAgent>.

=head1 AUTHOR

Frank Wiegand, C<< <frank.wiegand at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-moviepilot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Moviepilot>.
I will be notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Moviepilot

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Moviepilot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Moviepilot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Moviepilot>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Moviepilot/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the moviepilot.de team for providing an API key for
developing and testing this module.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Frank Wiegand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
