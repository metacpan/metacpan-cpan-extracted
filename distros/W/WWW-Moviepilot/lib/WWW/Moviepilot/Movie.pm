package WWW::Moviepilot::Movie;

use warnings;
use strict;

use Carp;
use JSON::Any;
use URI;
use URI::Escape;

use WWW::Moviepilot::Person;

=head1 NAME

WWW::Moviepilot::Movie - Handle moviepilot.de movies

=head1 SYNOPSIS

    my $movie = WWW::Moviepilot->new(...)->movie( 'matrix' );

    # all fields
    my @fields = $movie->fields;

    # direct access to fields
    print $movie->display_title; # "Matrix"
    print $movie->title;         # field does not exist => undef

    # *_lists in scalar context
    print scalar $movie->emotions_list; # "Spannend,Aufregend"

    # *_lists in list context
    print join ' +++ ', $movie->emotions_list # "Spannend +++ Aufregend"

=head1 METHODS

=head2 new

Creates a blank WWW::Moviepilot::Movie object.

    my $movie = WWW::Moviepilot::Movie->new;

=cut

sub new {
    my ($class, $args) = @_;
    my $self = bless {
        cast => [],
        data => {},
        name => undef,
        m    => $args->{m}
    } => $class;
    return $self;
}

=head2 populate( $args )

Populates an object with data, you should not use this directly.

=cut

sub populate {
    my ($self, $args) = @_;
    $self->{data} = $args->{data};
    if ( $self->restful_url ) {
        ($self->{name}) = $self->restful_url =~ m{/([^/]+)$};
    }
}

=head2 character

If used together with a filmography search, you get the name of the character
the person plays in the movie.

    my @filmography = $person->filmography;
    foreach my $movie (@filmography) {
        printf "%s plays %s\n", $person->last_name, $movie->character;
    }

=cut

sub character {
    my $self = shift;
    return $self->{data}{character};
}

=head2 name

Returns the internal moviepilot name for the movie.

    my @movies = WWW::Moviepilot->new(...)->search_movie( 'matrix' );
    foreach my $movie (@movies) {
        print $movie->name;
    }
    __END__
    matrix
    armitage-iii-dual-matrix
    the-matrix-reloaded
    the-matrix-revolutions
    madrid
    mourir-a-madrid
    die-sieben-kleider-der-katrin
    super-mario-bros
    armitage-iii-polymatrix
    rendezvous-in-madrid
    herr-puntila-und-sein-knecht-matti
    drei-maedchen-in-madrid
    zwischen-madrid-und-paris
    marie-antoinette-2
    mario-und-der-zauberer
    bezaubernde-marie-2
    marie-lloyd
    marie-line
    marie-antoinette-3
    maria-magdalena

=cut

sub name {
    my $self = shift;
    return $self->{name};
}

=head2 cast

Returns the cast for the movie.

    my $movie = WWW::Moviepilot->new(...)->movie(...);
    my @cast = $movie->cast;

Returned is a list of L<WWW::Moviepilot::Person> objects.

=cut

sub cast {
    my ($self, $movie) = @_;

    # we have already a cast
    if ( @{ $self->{cast} } ) {
        return @{ $self->{cast} };
    }

    if ( !$movie && !$self->name ) {
        croak "no movie name provided, can't fetch cast";
    }

    $movie ||= $self->name;

    my $uri = URI->new( $self->{m}->host . '/movies/' . uri_escape($movie) . '/casts.json' );
    $uri->query_form( api_key => $self->{m}->api_key );

    my $res = $self->{m}->ua->get( $uri->as_string );
    if ( $res->is_error ) {
        croak $res->status_line;
    }

    my $o = JSON::Any->from_json( $res->decoded_content );
    foreach my $entry ( @{ $o->{movies_people} } ) {
        my $person = WWW::Moviepilot::Person->new({ m => $self->{m} });
        $person->populate({ data => $entry });
        push @{ $self->{cast} }, $person;
    }

    return @{ $self->{cast} };
}

=head2 fields

Returns a list with all fields for this movie.

    my @fields = $movie->fields;

    # print all fields
    foreach my $field ( @fields ) {
        printf "%s: %s\n", $field. $movie->$field;
    }

As of 2009-10-13, these fields are supported:

=over 4

=item * alternative_identifiers

=item * average_community_rating

=item * average_critics_rating

=item * cinema_start_date

=item * countries_list

=item * display_title

=item * dvd_start_date

=item * emotions_list

=item * genres_list

=item * homepage

=item * long_description

=item * on_tv

=item * places_list

=item * plots_list

=item * poster

=item * premiere_date

=item * production_year

=item * restful_url

=item * runtime

=item * short_description

=item * times_list

=back

=cut

sub fields {
    my $self = shift;
    return keys %{ $self->{data}{movie} };
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $field = $AUTOLOAD;
    $field =~ s/.*://;
    if ( !exists $self->{data}{movie}{$field} ) {
        return;
    }

    if ( $field =~ /_list$/ && wantarray ) {
        return split /,/, $self->{data}{movie}{$field};
    }

    return $self->{data}{movie}{$field};
}

1;
__END__

=head1 AUTHOR

Frank Wiegand, C<< <frank.wiegand at gmail.com> >>

=head1 SEE ALSO

L<WWW::Moviepilot>, L<WWW::Moviepilot::Person>.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Frank Wiegand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
