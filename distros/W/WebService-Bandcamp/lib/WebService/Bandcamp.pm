package WebService::Bandcamp;
use JSON::XS;
use Cache::LRU;
use Net::DNS::Lite;
use Furl;
use URI;
use URI::QueryParam;
use Carp;
use Moo;
use namespace::clean;
our $VERSION = "0.06";


$Net::DNS::Lite::CACHE = Cache::LRU->new( size => 512 );

has 'api_key' => (
    is => 'rw',
    isa => sub { $_[0] },
    required => 1,
    default => sub { $ENV{BANDCAMP_API_KEY} },
);

has 'http' => (
    is => 'rw',
    required => 1,
    default  => sub {
        my $http = Furl::HTTP->new(
            inet_aton => \&Net::DNS::Lite::inet_aton,
            agent => 'WebService::Bandcamp/' . $VERSION,
            headers => [ 'Accept-Encoding' => 'gzip',],
        );
        $http->env_proxy;
        return $http;
    },
);


sub band_search {
    my ($self, %query_param) = @_;
    return $self->_make_request('api/band/3/search', \%query_param);
}

sub band_discography {
    my ($self, %query_param) = @_;
    return $self->_make_request('api/band/3/discography', \%query_param);
}

sub band_info {
    my ($self, %query_param) = @_;
    return $self->_make_request('api/band/3/info', \%query_param);
}

sub album_info {
    my ($self, %query_param) = @_;
    return $self->_make_request('api/album/2/info', \%query_param);
}

sub track_info {
    my ($self, %query_param) = @_;
    return $self->_make_request('api/track/3/info', \%query_param);
}

sub url_info {
    my ($self, %query_param) = @_;
    return $self->_make_request('api/url/1/info', \%query_param);
}

sub _make_request {
    my ( $self, $path, $query_param ) = @_;

    my $query = URI->new;
    $query->query_param( 'key', $self->api_key );
    map { $query->query_param( $_, $query_param->{$_} ) } keys %$query_param;

    my ($minor_version, $code, $message, $headers, $content) = 
    $self->http->request(
        scheme => 'http',
        host => 'api.bandcamp.com',
        path_query => "$path$query",
        method => 'GET',
    );

    my $data = decode_json( $content );
    if ( defined $data->{error} ) {
        my $code = $data->{error};
        my $message = $data->{message};
        confess "$code: $message";
    } else {
        return $data;
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Bandcamp - A simple and fast interface to the bandcamp.com API

=head1 SYNOPSIS

    use WebService::Bandcamp;

    my $bandcamp WebService::Bandcamp->new( api_key => 'YOUR_API_KEY' );

    # or default value $ENV{'BANDCAMP_API_KEY'}
    my $bandcamp WebService::Bandcamp->new();

    my $data = $bandcamp->band_search(name => 'metal');
    $data = $bandcamp->band_discography(band_id => 666);
    $data = $bandcamp->band_info(band_id => 666);
    $data = $bandcamp->album_info(album_id => 666);
    $data = $bandcamp->track_info(track_id => 666);
    $data = $bandcamp->url_info(url => 'http://example.com/band_or_album_or_track_url');

=head1 DESCRIPTION

The module provides a simple interface to the Bandcamp.com API. To use this module, you must first sign up at L<http://bandcamp.com/developer> to receive an API key.

=head1 SEE ALSO

L<http://bandcamp.com/developer>

=head1 LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hondallica E<lt>hondallica@gmail.comE<gt>

=cut

