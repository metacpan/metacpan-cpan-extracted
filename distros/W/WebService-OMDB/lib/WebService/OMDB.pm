use 5.010;
use strict;
use warnings;

package WebService::OMDB;
{
  $WebService::OMDB::VERSION = '1.140440';
}

# ABSTRACT: Interface to http://www.omdbapi.com/

use LWP::UserAgent;
use JSON;

use constant BASE_URL => 'http://www.omdbapi.com/';

sub search {
    my ( $s, $options ) = @_;

    die "search string is required" unless $s;

    my $response = _get( 's', $s, $options );
    if ( $response->is_success ) {

        my $content = decode_json( $response->content );
        return $content->{Search};
    }
    else {
        die $response->status_line;
    }
}

sub id {
    my ( $i, $options ) = @_;

    die "id is required" unless $i;

    my $response = _get( 'i', $i, $options );
    if ( $response->is_success ) {

        my $content = decode_json( $response->content );
        return $content;
    }
    else {
        die $response->status_line;
    }

}

sub title {
    my ( $t, $options ) = @_;

    die "title is required" unless $t;

    my $response = _get( 't', $t, $options );
    if ( $response->is_success ) {

        my $content = decode_json( $response->content );
        return $content;
    }
    else {
        die $response->status_line;
    }

}

sub _get {
    my ( $search_param, $search_term, $options ) = @_;

    my $url = _generate_url( $search_param, $search_term, $options );
    my $ua = LWP::UserAgent->new();
    $ua->agent( $options->{user_agent} ) if $options->{user_agent};
    return $ua->get($url);
}

# generates a url from the options
sub _generate_url {
    my ( $search_param, $search_term, $options ) = @_;

    my $url = sprintf( "%s?%s=%s", BASE_URL, $search_param, $search_term );

    while ( my ( $key, $value ) = each(%$options) ) {
        $url .= sprintf( "&%s=%s", $key, $value // 0 );
    }

    return $url;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OMDB - Interface to http://www.omdbapi.com/

=head1 VERSION

version 1.140440

=head1 SYNOPSIS

  my $search_results = WebService::OMDB::search('The Geen Mile');
  # returns...
  [
    {
      'Year' => '1999',
      'Type' => 'movie',
      'imdbID' => 'tt0120689',
      'Title' => 'The Green Mile'
    },
    {
      'Year' => '1999',
      'Type' => 'movie',
      'imdbID' => 'tt0338255',
      'Title' => 'The Miracle of \'The Green Mile\''
    },
    {
      'Year' => '2006',
      'Type' => 'movie',
      'imdbID' => 'tt0960803',
      'Title' => 'Miracles and Mystery: Creating \'The Green Mile\''
    },
    {
      'Year' => '2009',
      'Type' => 'episode',
      'imdbID' => 'tt1903167',
      'Title' => 'The Green Mile'
    }
  ];

  my $id_result = WebService::OMDB::id('tt0120689');
  # returns...
  {
    'Director' => 'Frank Darabont',
    'imdbID' => 'tt0120689',
    'Poster' => '...',
    'Actors' => 'Tom Hanks, David Morse, Michael Clarke Duncan, Bonnie Hunt',
    'Metascore' => '61',
    'imdbRating' => '8.5',
    'imdbVotes' => '477,025',
    'Released' => '10 Dec 1999',
    'Awards' => 'Nominated for 4 Oscars. Another 15 wins & 23 nominations.',
    'Title' => 'The Green Mile',
    'Plot' => 'The lives of guards on Death Row are affected by one of their charges: a black man accused of child murder and rape, yet who has a mysterious gift.',
    'Year' => '1999',
    'Rated' => 'R',
    'Writer' => 'Stephen King (novel), Frank Darabont (screenplay)',
    'Type' => 'movie',
    'Runtime' => '189 min',
    'Genre' => 'Crime, Drama, Fantasy',
    'Language' => 'English, French',
    'Response' => 'True',
    'Country' => 'USA'
  };

  my $title_result = WebService::OMDB::title('The Green Mile');
  # returns the same as id

=head1 DESCRIPTION

WebService::OMDB is an interface to L<http://www.omdbapi.com/>.

=head1 METHODS

=head2 search( $search_term, $options )

Searches based on the title. Returns an array of results.

=over 4

=item search_term

String. Required.

=item options

The options shown at L<http://www.omdbapi.com/>. Hash reference. Optional.

=back

=head2 id( $id )

Gets a result based on the IMDB id. Returns a single result.

=over 4

=item id

String. Required.

=item options

The options shown at L<http://www.omdbapi.com/>. Hash reference. Optional.

=back

=head2 title( $title )

Gets a result based on the title. Returns a single result.

=over 4

=item title

String. Required.

=item options

The options shown at L<http://www.omdbapi.com/>. Hash reference. Optional.

=back

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
