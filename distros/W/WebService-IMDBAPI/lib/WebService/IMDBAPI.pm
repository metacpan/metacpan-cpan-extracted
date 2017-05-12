use strict;
use warnings;

package WebService::IMDBAPI;
{
  $WebService::IMDBAPI::VERSION = '1.130150';
}

# ABSTRACT: Interface to http://imdbapi.org/

use WebService::IMDBAPI::Result;

use LWP::UserAgent;
use JSON;

# default options
use constant DEFAULT_USER_AGENT => 'Mozilla/5.0';
use constant DEFAULT_LANG       => 'en-US';

use constant BASE_URL => 'http://imdbapi.org/?type=json';

use Object::Tiny qw(
  user_agent
  language
);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    unless ( $self->user_agent ) {
        $self->{user_agent} = DEFAULT_USER_AGENT;
    }
    unless ( $self->language ) {
        $self->{language} = DEFAULT_LANG;
    }

    return $self;
}

sub search_by_title {
    my ( $self, $title, $options ) = @_;

    unless ($title) {
        die "title is required";
    }
    $options->{title} = $title;

    my $response = $self->_do_search($options);
    if ( $response->is_success ) {

        my $content = decode_json( $response->content );

        my @results;
        if ( ref($content) eq 'ARRAY' ) {

            for ( @{ decode_json( $response->content ) } ) {
                my $result = WebService::IMDBAPI::Result->new( %{$_} );
                push( @results, $result );
            }
        }
        return \@results;
    }
    else {
        die $response->status_line;
    }
}

sub search_by_id {
    my ( $self, $id, $options ) = @_;

    unless ($id) {
        die "id is required";
    }
    $options->{id} = $id;

    my $response = $self->_do_search($options);
    if ( $response->is_success ) {

        my $content = decode_json( $response->content );

        if ( $content->{error} ) {
            return;
        }
        my $result = WebService::IMDBAPI::Result->new( %{$content} );
        return $result;
    }
    else {
        die $response->status_line;
    }
}

# carries out the search and returns the response
sub _do_search {
    my ( $self, $options ) = @_;

    my $url = $self->_generate_url($options);
    my $ua  = LWP::UserAgent->new();
    $ua->agent( $self->{user_agent} );
    return $ua->get($url);
}

# generates a url from the options
sub _generate_url {
    my ( $self, $options ) = @_;

    my $url = sprintf( "%s&lang=%s", BASE_URL, $self->{language} );

    while ( my ( $key, $value ) = each(%$options) ) {
        $url .= sprintf( "&%s=%s", $key, $value || 0 );
    }

    return $url;
}

1;



=pod

=head1 NAME

WebService::IMDBAPI - Interface to http://imdbapi.org/

=head1 VERSION

version 1.130150

=head1 SYNOPSIS

  my $imdb = WebService::IMDBAPI->new();
  
  # an array of up to 1 result
  my $results = $imdbapi->search_by_title('In Brugges', { limit => 1 });
  
  # an WebService::IMDBAPI::Result object
  my $result = $results->[0];
  
  say $result->title;
  say $result->plot_simple;

=head1 DESCRIPTION

WebService::IMDBAPI is an interface to L<http://imdbapi.org/>.

=head1 METHODS

=head2 new

Creates a new WebService::IMDBAPI object. Takes the following optional parameters:

=over 4

=item user_agent

The user agent to use. Note that the default LWP user agent seems to be blocked. Defaults to C<Mozilla/5.0>.

=item language

The language for the results. Defaults to C<en-US>.

=back

=head2 search_by_title( $title, $options )

Searches based on a title. For the options and their defaults, see L<http://imdbapi.org/#search-by-title>.

Some of the most common options are:

=over 4

=item limit

Limits the number of results. Defaults to 1.

=item plot

The plot type you wish the API to return (none, simple or full). Defaults to simple.

=item release

The release date type you wish the API to return (simple or full). Defaults to simple.

=back

C<$title> is required. C<$options> are optional.

Returns an array of L<WebService::IMDBAPI::Result> objects.

=head2 search_by_id( $id, $options )

Searches based on an IMDB ID. For the options and their defaults, see L<http://imdbapi.org/#search-by-id>.

C<$id> is required. C<$options> are optional.

Returns a single L<WebService::IMDBAPI::Result> object.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

