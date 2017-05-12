package WebService::Decibel;
use JSON::XS;
use Cache::LRU;
use Net::DNS::Lite;
use Furl;
use URI;
use URI::QueryParam;
use Carp;
use Moo;
use namespace::clean;
our $VERSION = "0.03";


$Net::DNS::Lite::CACHE = Cache::LRU->new( size => 512 );

has 'app_id' => (
    is => 'rw',
    isa => sub { $_[0] },
    required => 1,
    default => sub { $ENV{DECIBEL_APPLICATION_ID} },
);

has 'app_key' => (
    is => 'rw',
    isa => sub { $_[0] },
    required => 1,
    default => sub { $ENV{DECIBEL_APPLICATION_KEY} },
);

my $build_http = sub {
    my $self = shift;
    my $http = Furl::HTTP->new(
        inet_aton => \&Net::DNS::Lite::inet_aton,
        agent => 'WebService::Decibel/' . $VERSION,
        headers => [
            'Accept-Encoding' => 'gzip',
            'DecibelAppID' => $self->app_id,
            'DecibelAppKey' => $self->app_key,
            'DecibelTimestamp' => '20140903 17:22:33',
        ],
    );
    return $http;
};

has 'http' => (
    is => 'lazy',
    required => 1,
    default  => $build_http,
);

my @methods = qw( album albums artist artists disctags image recording recordings );
for my $method (@methods) {
    my $code = sub {
        my ($self, %query_param) = @_;
        return $self->request($method, \%query_param);
    };
    no strict 'refs';
    *{$method} = $code; 
}


sub request {
    my ( $self, $path, $query_param ) = @_;

    my $query = URI->new;
    map { $query->query_param( $_, $query_param->{$_} ) } keys %$query_param;

    my ($minor_version, $status_code, $message, $headers, $content) = 
        $self->http->request(
            scheme => 'http',
            host => 'rest.decibel.net',
            path_query => "v2/$path$query",
            method => 'GET',
        );

    if ( $content !~ /^\{/) {
        confess $content;
    } else {
        return decode_json( $content );
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Decibel - A simple and fast interface to the Decibel API

=head1 SYNOPSIS

    use WebService::Decibel;

    my $decibel = new WebService::Decibel(
        app_id  => 'YOUR_APPLICATION_ID',
        app_key => 'YOUR_APPLICATION_KEY',
    );

    my $album = $decibel->album(id => '9e7eb16c-358f-e311-be87-ac220b82800d');
    my $albums = $decibel->albums(artistName => 'Metallica');
    my $artist = $decibel->artist(id => '09ff7ede-318f-e311-be87-ac220b82800d');
    my $artists = $decibel->artists(name => 'Metallica');
    my $disctags = $decibel->disctags(id => '9e7eb16c-358f-e311-be87-ac220b82800d');
    my $recording = $decibel->recording(id => '01f034fc-b76c-11e3-be98-ac220b82800d');
    my $recordings = $decibel->recordings(artist => 'Metallica', title => 'Battery');

=head1 DESCRIPTION

The module provides a simple interface to the www.decibel.net API. To use this module, you must first sign up at L<https://developer.decibel.net> to receive an Application ID and Key.

=head1 METHODS

These methods usage: L<https://developer.decibel.net/our-api>

=head3 album

    my $album = $decibel->album(id => '9e7eb16c-358f-e311-be87-ac220b82800d');

=head3 albums

    my $albums = $decibel->albums(artistName => 'Metallica');

=head3 artist

    my $artist = $decibel->artist(id => '09ff7ede-318f-e311-be87-ac220b82800d');

=head3 artists

    my $artists = $decibel->artists(name => 'Metallica');

=head3 disctags

    my $disctags = $decibel->disctags(id => '9e7eb16c-358f-e311-be87-ac220b82800d');

=head3 recording

    my $recording = $decibel->recording(id => '01f034fc-b76c-11e3-be98-ac220b82800d');

=head3 recordings

    my $recordings = $decibel->recordings(artist => 'Metallica', title => 'Battery');


=head1 SEE ALSO

L<https://developer.decibel.net>

=head1 LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hondallica E<lt>hondallica@gmail.comE<gt>

=cut

