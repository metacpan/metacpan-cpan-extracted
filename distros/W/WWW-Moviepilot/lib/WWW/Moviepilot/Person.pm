package WWW::Moviepilot::Person;

use warnings;
use strict;

use Carp;
use JSON::Any;
use URI;
use URI::Escape;

use WWW::Moviepilot::Movie;

=head1 NAME

WWW::Moviepilot::Person - Handle moviepilot.de people

=head1 SYNOPSIS

    my $person = WWW::Moviepilot->new->(...)->person( 'paul-newman' );

    # all fields
    my @fields = $person->fields;

    # direct access to fields
    print $person->date_of_death; # "2008-09-26"
    print $person->title;         # field does not exist => undef

=head1 METHODS

=head2 new

Creates a blank WWW::Moviepilot::Person object.

    my $person = WWW::Moviepilot::Person->new;

=cut

sub new {
    my ($class, $args) = @_;
    my $self = bless {
        filmography => [],
        name        => undef,
        m           => $args->{m},
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

If used together with a movie search, you get the name of the character
the person plays in the movie.

    my @cast = $movie->cast;
    foreach my $person (@cast) {
        printf "%s plays %s\n", $person->last_name, $person->character;
    }

=cut

sub character {
    my $self = shift;
    return $self->{data}{character};
}

=head2 name

Returns the internal moviepilot name for the person.

    my @people = WWW::Moviepilot->new(...)->search_person( 'paul-newman' );
    foreach my $person (@people) {
        print $person->name;
    }

=cut

sub name {
    my $self = shift;
    return $self->{name};
}

=head2 filmography

Returns the filmography for the person.

    my $person = WWW::Moviepilot->new(...)->person(...);
    my @filmography = $person->cast;

Returned is a list of L<WWW::Moviepilot::Person> objects.

=cut

sub filmography {
    my ($self, $name) = @_;

    # we have already a filmography
    if ( @{ $self->{filmography} } ) {
        return @{ $self->{filmography} };
    }

    if ( !$name && !$self->name ) {
        croak "no name provided, can't fetch filmography";
    }

    $name ||= $self->name;

    my $uri = URI->new( $self->{m}->host . '/people/' . uri_escape($name) . '/filmography.json' );
    $uri->query_form( api_key => $self->{m}->api_key );

    my $res = $self->{m}->ua->get( $uri->as_string );
    if ( $res->is_error ) {
        croak $res->status_line;
    }

    my $o = JSON::Any->from_json( $res->decoded_content );
    foreach my $entry ( @{ $o->{movies_people} } ) {
        my $movie = WWW::Moviepilot::Movie->new({ m => $self->{m} });
        $movie->populate({ data => $entry });
        push @{ $self->{filmography} }, $movie;
    }

    return @{ $self->{filmography} };
}

=head2 fields

Returns a list with all fields for this person.

    my @fields = $person->fields;

    # print all fields
    foreach my $field (@fields) {
        printf "%s: %s\n", $field. $person->$field;
    }

As of 2009-10-14, these fields are supported:

=over 4

=item * date_of_birth

=item * date_of_death

=item * first_name

=item * homepage

=item * last_name

=item * long_description

=item * pseudonyms

=item * restful_url

=item * sex

=item * short_description

=back

=cut

sub fields {
    my $self = shift;
    return keys %{ $self->{data}{person} };
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $field = $AUTOLOAD;
    $field =~ s/.*://;
    if ( !exists $self->{data}{person}{$field} ) {
        return;
    }

    return $self->{data}{person}{$field};
}

1;
__END__

=head1 AUTHOR

Frank Wiegand, C<< <frank.wiegand at gmail.com> >>

=head1 SEE ALSO

L<WWW::Moviepilot>, L<WWW::Moviepilot::Movie>.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Frank Wiegand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
