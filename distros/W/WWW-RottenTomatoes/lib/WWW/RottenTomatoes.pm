package WWW::RottenTomatoes;

use URI::Escape;
use Carp qw{croak};
	
use base qw{REST::Client};

our $VERSION = 0.03;

sub new {
    my ( $class, %args ) = @_;

    my $self = $class->SUPER::new(
	host => 'http://api.rottentomatoes.com/api/public/v1.0'
    );
    $self->getUseragent()->agent("perl-WWW-RottenTomatoes/$VERSION");

    bless $self, $class;

    # pass params to object
    for my $key ( keys %args ) {
        $self->{$key} = $args{$key};
    } 

    $self->{params} = '.json?apikey=' . $self->{api_key};
    if ( $self->{pretty_print} eq 'true') {
        $self->{params} .= '&_prettyprint=' . $self->{pretty_print};
    }

    return $self;
}

sub movies_search {
    my ( $self, %args ) = @_;

    if ( !$args{query} ) {
        croak 'movie_search method requires a "query" parameter';
    }

    if ( $args{query} ) { 
        $self->{params} .= '&q=' . uri_escape( $args{query} );
    }
    if ( $args{page} ) {
        $self->{params} .= '&page=' . $args{page};
    }
    if ( $args{page_limit} ) {
        $self->{params} .= '&page_limit=' . $args{page_limit};
    }

    $self->GET( '/movies' . $self->{params} );

    return $self->responseContent;
}

sub lists_directory {
    my ( $self ) = @_;

    $self->GET( '/lists' . $self->{params} );

    return $self->responseContent;
}

sub movie_lists_directory {
    my ( $self ) = @_;

    $self->GET( '/lists/movies' . $self->{params} );

    return $self->responseContent;
}

sub dvd_lists_directory {
    my ( $self ) = @_;

    $self->GET( '/lists/dvds' . $self->{params} );

    return $self->responseContent;
}

sub opening_movies {
    my ( $self, %args ) = @_;

    if ( $args{limit} ) {
        $self->{params} .= '&limit=' . $args{limit};
    }
    if ( $args{country} ) {
        $self->{params} .= '&country=' . $args{country};
    }

    $self->GET( '/lists/movies/opening' . $self->{params} );

    return $self->responseContent;
}

sub upcoming_movies {
    my ( $self, %args ) = @_;

    if ( $args{country} ) {
        $self->{params} .= '&country=' . $args{country};
    }
    if ( $args{page} ) { 
         $self->{params} .= '&page=' . $args{page};
    }
    if ( $args{page_limit} ) {
         $self->{params} .= '&page_limit=' . $args{page_limit};
    }

    $self->GET( '/lists/movies/upcoming' . $self->{params} );

    return $self->responseContent;
}

sub new_release_dvds {
    my ( $self, %args ) = @_;

    if ( $args{country} ) {
	$self->{params} .= '&country=' . $args{country};
    }
    if ( $args{page} ) {
	$self->{params} .= '&page=' . $args{page};
    }
    if ( $args{page_limit} ) {
        $self->{params} .= '&page_limit=' . $args{page_limit};
    }

    $self->GET( '/lists/dvds/new_releases' . $self->{params} );

    return $self->responseContent;
}

sub movie_info {
    my ( $self, %args ) = @_;

    if ( !$args{movie_id} ) {
        croak 'movie_info method requires a "movie_id" parameter';
    }

    $self->GET( "/movies/$args{movie_id}" . $self->{params} );

    return $self->responseContent;
}

sub movie_cast {
    my ( $self, %args ) = @_;

    if ( !$args{movie_id} ) {
        croak 'movie_cast method requires a "movie_id" parameter'
    }

    $self->GET( 
	"/movies/$args{movie_id}/cast" . $self->{params} );

    return $self->responseContent;
}

sub movie_reviews {
    my ( $self, %args ) = @_;

    if ( !$args{movie_id} ) {
        croak 'movie_reviews method requires a "movie_id" parameter';
    }

    if ( $args{review_type} ) {
	$self->{params} .= '&review_type=' . $args{review_type};
    }
    if ( $args{country} ) {
	$self->{params} .= '&country=' . $args{country};
    }
    if ( $args{page} ) {
	$self->{params} .= '&page=' . $args{page};
    }
    if ( $args{page_limit} ) {
	$self->{params} .= '&page_limit=' . $args{page_limit};
    }

    $self->GET( "/movies/$args{movie_id}/reviews" . $self->{params} );

    return $self->responseContent;
}

sub movie_similar {
    my ( $self, %args ) = @_;

    if ( !$args{movie_id} ) {
	 croak 'movie_similar method requires a "movie_id" parameter';
    }

    if ( $args{limit} ) {
         $self->{params} .= '&limit=' . $args{limit};
    }

    $self->GET( "/movies/$args{movie_id}/similar" . $self->{params} );

    return $self->responseContent;
}

sub in_theatre_movies {
    my ( $self, %args ) = @_;

    if ( $args{country} ) {
        $self->{params} .= '&country=' . $args{country};
    }
    if ( $args{page} ) {
        $self->{params} .= '&page=' . $args{page};
    }
    if ( $args{page_limit} ) {
        $self->{params} .= '&page_limit=' . $args{page_limit};
    }

    $self->GET( '/lists/movies/in_theaters' . $self->{params} );

    return $self->responseContent;
}

sub callback {
    my ( $self, %args ) = @_;

    if ( !$args{callback_fn} ) {
        croak 'callback method requires a "callback_fn" parameter';
    }

    $self->{params} .= '&callback=' . $args{callback_fn};

    $self->GET( $self->{params} );

    return $self->responseContent;
}

1;

__END__

=head1 NAME

WWW::RottenTomatoes - A Perl interface to the Rotten Tomatoes API

=head1 VERSION

Version 0.03

=head1 SYNPOSIS

    use WWW::RottenTomatoes;

    my $rt = WWW::RottenTomatoes->new(
        api_key      => 'your_api_key',
        pretty_print => 'true'
    );

    $rt->movies_search( query => 'The Goonies' );

=head1 DESCRIPTION

This module is intended to provide an interface between Perl and the Rotten
Tomatoes JSON API. The Rotten Tomatoes API is a RESTful web service. In order
to use this library you must provide an api key which requires registration.
For more information please see Http://dev.rottentomatoes.com    

=head1 CONSTRUCTOR

=head2 new()

Creates and returns a new WWW::RottenTomatoes object

    my $api= WWW::RottenTomatoes->new()

=over 4

=item * C<< api_key => [your_api_key] >>

The api_key parameter is required. You must provide a valid key.

=item * C<< pretty_print => [true] >>

This parameter allows you to enable the pretty print function of the API. By
default this parameter is set to false meaning you do not have to specify the
parameter unless you intend to set it to true.

=back

=head1 SUBROUTINES/METHODS

=head2 $obj->movies_search(...)

The movies search endpoint for plain text queries

    $api->movies_search( 
	query      => $search_query,
        page       => $page,
        page_limit => $page_limit 
    );

* B< query > S< string, required: true >

plain text search query

* B< page_limit > S< integer, required: false, default: 30 >

the amount of movie search results to show per page

* B< page > S< integer, required: false, default: 1 >

the selected page of movie search results

=head2 $obj->lists_directory

Displays the top level lists available in the API

* no parameters required

=head2 $obj->movie_lists_directory

Shows the movie lists we have available

* no parameters required

=head2 $obj->dvd_lists_directory

Shows the DVD lists we have available

* no parameters required

=head2 $obj->opening_movies(...)

Retrieves current opening movies

    $obj->opening_movies(
        limit   => 5,
        country => 'us'
    );

* B< limit > S< integer, required: false, default: 16 >

limits number of movies returned

* B< country > S< string, required: false, default: "us" >

provides localized data for selected country (ISO 3166-1 alpha-2)

=head2 $obj->upcoming_movies(...)

Retrieves upcoming movies

    $obj->upcoming_movies(
        page_limit => 5,
        page       => 2,
        country    => 'uk'
    ); 

* B< page_limit > S< integer, required: false, default: 16 >

the amount of upcoming movies to show per page

* B< page > S< integer, required: false, default: 1 >

the selected page of upcoming movies

* B< country > S< string, required: false, default: "us" >

provides localized data for selected country (ISO 3166-1 alpha-2)

=head2 $obj->new_release_dvds(...)

Retrieves new release dvds

    $obj->new_release_dvds(
        page_limit => 10,
        page       => 3,
        country    => 'ca'
    );

* B< page_limit > S< integer, required: false, default: 16 >

The amount of new release dvds to show per page

* B< page > S< integer, required: false, default: 1 >

The selected page of new release dvds

* B< country > S< string, required: false, default: "us" >

provides localized data for selected country (ISO 3166-1 alpha-2)

=head2 $obj->movie_info(...)

Detailed information on a specific movie specified by Id. You can use the
movies search endpoint or peruse the lists of movies/dvds to get the urls to
movies.

     $obj->movie_info( movie_id => 770672122 ); 

* B< movie_id > S< integer, required: true >

The unique id (value) for a movie

=head2 $obj->movie_cast(...)

Pulls the complete movie cast for a movie

     $obj->movie_cast( movie_id => 770672122 );

* B< movie_id > S< integer, required: true >

The unique id (value) for a movie

=head2 $obj->movie_reviews(...)

Retrieves the reviews for a movie. Results are paginated if they go past the
specified page limit

    $obj->movie_reviews(
        movie_id    => 770672122,
        review_type => 'dvd',
        page_limit  => 1,
        page        => 5,
        country     => 'us'
    );

* B< movie_id > S< integer, required: true >

The unique id (value) for a movie

* B< review_type > S< string, required: false, default: top_critic >

3 different review types are possible: "all", "top_critic" and  "dvd".
"top_critic" shows all the Rotten "top_critic" shows all the Rotten. "dvd"
pulls the reviews given on the DVD of the movie. "all" as the name implies
retrieves all reviews

* B< page_limit > S< integer, required: false, default: 16 >

The amount of movie reviews to show per page

* B< page > S< integer, required: false, default: 1 >

The selected page of movie reviews

* B< country > S< string, required: false, default: "us" > 

provides localized data for selected country (ISO 3166-1 alpha-2)

=head2 $obj->movie_similar(...)

Shows similar movies for a movies

    $obj->movies_similar(
        movie_id => 770672122,
	limit    => 3
    );

* B< movie_id > S< integer, required: true >

The unique id (value) for a movie

=head2 $obj->in_theatre_movies(...)

Retrieves movies currently in theaters

    $obj->in_theatre_movies(
        page_limit  => 3,
        page        => 2,
        country     => 'mx'
    );

* B< page_limit > S< integer, required: false, default: 16 >

The amount of in theatre movies to show per page

* B< page > S< integer, required: false, default: 1 >

The selected page of in theatre movies

* B< country > S< string, required: false, default: "us" >

provides localized data for selected country (ISO 3166-1 alpha-2)

=head2 $obj->callback(...)

JSONP Support

    $obj->callback(
        callback_fn => method();
    );

* B< callback_fn >

The API supports JSONP calls. Simply append a callback parameter with the name
of your callback method at the end of the request. 

=head1 DIAGNOSTICS 

N/A at the current point in time

=head1 CONFIGURATION AND ENVIRONMENT

This package has only been tested in a 64bit Unix (OSX) environment however
it does not make usage of any code or modules considered OS specific and no
special configuration and or configuration files are needed. 

=head1 INCOMPATIBILITIES

This package is intended to be compatible with Perl 5.008 and beyond.

=head1 BUGS AND LIMITATIONS

Current limitations exist in the amount of http requests that can be made
against the API. The scope of this limitation exists outside of the code base.

=head1 DEPENDENCIES

B<REST::Client>, B<URI::Escape>

=head1 SEE ALSO

B<http://developer.rottentomatoes.com/docs>

You may notice differences in the required parameters of this script and the
documentation. The differences are typically stop gaps to prevent the API from
empty results. A good example is the movie_search method. Without a text ( or a
url encoded ) search term you will not return any results.

=head1 SUPPORT

The module is provided free of support however feel free to contact the
author or current maintainer with questions, bug reports, and patches.

Considerations will be taken when making changes to the API. Any changes to
its interface will go through at the least one deprecation cycle.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Casey W. Vega.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without
any warranty; without even the implied warranty of merchantability or
fitness for a particular purpose.

=head1 Author

Casey Vega <cvega@cpan.org>

=cut
