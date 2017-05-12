package WebService::GigaTools;
use JSON::XS;
use Cache::LRU;
use Net::DNS::Lite;
use Furl;
use URI;
use URI::QueryParam;
use Carp;
use Moo;
use namespace::clean;
our $VERSION = "0.01";


$Net::DNS::Lite::CACHE = Cache::LRU->new( size => 512 );

has 'api_key' => (
    is => 'rw',
    isa => sub { $_[0] },
    required => 1,
    default => sub { $ENV{GIGATOOLS_API_KEY} },
);

has 'http' => (
    is => 'rw',
    required => 1,
    default  => sub {
        my $http = Furl::HTTP->new(
            inet_aton => \&Net::DNS::Lite::inet_aton,
            agent => 'WebService::GigaTools/' . $VERSION,
            headers => [ 'Accept-Encoding' => 'gzip',],
        );
        return $http;
    },
);


my @methods = (
    'gigs',
    'city',
    'country',
    'venue',
    'search',
);


for my $method (@methods) {
    my $code = sub {
        my ($self, %query_param) = @_;
        return $self->request("$method.json", \%query_param);
    };
    no strict 'refs';
    *{$method} = $code; 
}


sub request {
    my ( $self, $path, $query_param ) = @_;

    my $query = URI->new;
    $query->query_param( 'api_key', $self->api_key );
    map { $query->query_param( $_, $query_param->{$_} ) } keys %$query_param;

    my ($minor_version, $status_code, $message, $headers, $content) = 
        $self->http->request(
            scheme => 'http',
            host => 'api.gigatools.com',
            path_query => "$path$query",
            method => 'GET',
        );

    my $data = decode_json( $content );
    if ( $status_code != 200 ) {
        confess "Error";
    } else {
        return $data;
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::GigaTools - A simple and fast interface to the GigaTools API

=head1 SYNOPSIS

    use WebService::GigaTools;

    my $gigatools = new WebService::GigaTools(api_key => 'YOUR_API_KEY');


=head1 DESCRIPTION

The module provides a simple interface to the GigaTools API. To use this module, you must first sign up at L<http://api.gigatools.com> to receive an API key.

=head1 METHODS

These methods usage: L<http://api.gigatools.com>

=head3 gigs

    my $data = $gigatools->gigs;

    $data = $gigatools->gigs(
        'from_date[]' => '2013-01-01',
        'to_date[]' => '2013-02-01',   
    );

=head3 city 

    my $data = $gigatools->city(
        'cities[]' => 'Berlin',
    );

    $data = $gigatools->city(
        'cities[]' => 'Berlin',
        'from_date[]' => '2013-01-01',
        'to_date[]' => '2013-02-01',   
    );

=head3 country

    my $data = $gigatools->country(
        'countries[]' => 'Japan',
    );

    $data = $gigatools->country(
        'countries[]' => 'Japan',
        'from_date[]' => '2014-11-09',
        'to_date[]' => '2014-11-15',   
    );

=head3 venue

    my $data = $gigatools->venue(
        'venues[]' => 'Berghain',
    );

    $data = $gigatools->venue(
        'venues[]' => 'Berghain',
        'from_date[]' => '2013-11-09',
        'to_date[]' => '2014-01-15',   
    );

=head3 search 

    my $data = $gigatools->search(
        'soundcloud_user_ids' => '1039,6251,19986369',
    );

    $data = $gigatools->search(
        'soundcloud_username' => 'jochempaap',
    );

    $data = $gigatools->search(
        'twitter_username' => 'djflash4eva',
    );

    $data = $gigatools->search(
        'mixcloud_username' => 'audioinjection',
    );

=head1 SEE ALSO

L<http://api.gigatools.com>

=head1 LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hondallica E<lt>hondallica@gmail.comE<gt>

=cut


