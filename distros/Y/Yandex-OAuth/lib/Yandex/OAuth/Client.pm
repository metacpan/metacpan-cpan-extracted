=encoding utf-8

=head1 NAME

Yandex::OAuth::Client - base class for any Yandex.API modules

=head1 SYNOPSIS

    use Yandex::OAuth::Client;

    my $client = Yandex::OAuth::Client->new(token => '************', endpoint => 'https://api-metrika.yandex.ru/');

    my $client->get(['stat','user_vars'], {
            pretty => 1,
            # other params specified for resource
        });
    # url converting to https://api-metrika.yandex.ru/stat/user_vars/?pretty=1

=head1 DESCRIPTION

Yandex::OAuth::Client is base class for any Yandex.API modules
Contains get, post, put, delete methods for queries to any APIs Yandex.

Looking for contributors for this and other Yandex.APIs

=cut

package Yandex::OAuth::Client;
use 5.008001;
use utf8;
use Modern::Perl;
use Data::Dumper;

use LWP::UserAgent;
use Storable qw/ dclone /;
use JSON::XS;
use Moo;

has 'ua' => (
    is => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new();
        $ua->agent( 'Yandex::OAuth Perl API Client' );
        $ua->timeout( 120 );
        return $ua;
    }
);

has 'token' => (
    is => 'rw',
    required => 1,
);

has 'endpoint' => (
    is => 'rw',
    required => 1,
);

has 'next_url' => (
    is => 'rw',
    default => '',
    writer  => 'set_next_url',
);

has 'demo' => (
    is => 'rw'
);

=head1 CONSTRUCTOR

=over

=item B<new()>

Require two arguments: token and endpoint. For module based on Yandex::OAuth::Client 
you can override atribute 'endpoint'
    
    extends 'Yandex::OAuth::Client';
    has '+endpoint' => (
        is      => 'ro',
        default => 'https://api-metrika.yandex.ru/',
    ); 

=back

=head1 METHODS

=over

=item B<get()>

Send GET request.

    $client->get(['stat','load']);
    
    # or full link. for example, when using "next" link from previous response

    $client->get('https://api-metrika.yandex.ru/stat/load/?pretty=1');

=cut

sub get {
    my ($self, $url, $query) = @_;

    return $self->request( 'get', $url, $query );
}

=item B<post()>

Send POST request.

    $client->post(['counters'], {
            # query params 
        }, {
            # body params
        });

=cut

sub post {
    my ($self, $url, $query, $body) = @_;

    return $self->request( 'post', $url, $query, $body );
}

=item B<put()>

Send PUT request.

    $client->put(['counter', $counter_id], {
            # query params 
        }, {
            # body params
        });

=cut

sub put {
    my ($self, $url, $query, $body) = @_;

    return $self->request( 'put', $url, $query, $body );
}

=item B<delete()>

Send DELETE request.

    $client->delete(['counter', $counter_id]);

=cut

sub delete {
    my ($self, $url, $query) = @_;

    return $self->request( 'delete', $url, $query );
}

sub request {
    my ( $self, $method, $url, $query, $body ) = @_;

    my $req = HTTP::Request->new( uc $method => $self->make_url( $url, $query ) );

    $self->prepare_request( $req, $body );

    my $resp = $self->parse_response( $self->ua->request( $req )->content );

    return $resp;
}

sub make_url {
    my ( $self, $resource, $params ) = @_;

    my @resources = ref $resource ? @$resource : ( $resource );

    my $url = '';
    if ( $resource =~ /^http/i ) {
        $url = $resource;
    }
    else {
        $url = $self->endpoint;
        $url =~ s/[\\\/]+$//;
        $url .= '/';
        $url .= join '/', @resources;
    }

    if ( $params ) {
        my $uri = URI->new( $url );
        $uri->query_form( %$params );
        $url = $uri->as_string;
    }

    return $url;
}

sub prepare_request {
    my ( $self, $request, $body_param ) = @_;

    my $body = '';
    if ( $body_param ) {
        my $params = dclone( $body_param );

        state $json = JSON::XS->new->utf8;

        $body = $json->encode( $params );

        $request->content( $body );
    }
    $request->header( 'content-type'   => 'application/json; charset=UTF-8' );
    $request->header( 'content-length' => length( $body ) );

    $request->header( 'Authorization' => 'Bearer ' . $self->token );

    return 1;
}

sub parse_response {
    my ( $self, $response ) = @_;

    return unless $response;

    my $json = JSON::XS::decode_json( $response );

    my $next = '';

    if ( defined $json->{links} && defined $json->{links}->{next} ) {
        $next = $json->{links}->{next};
        $next =~ s/^http:/https:/i;

        $self->set_next_url( $next );
    }

    return $json;
}


1;
__END__

=back

=head1 LICENSE

Copyright (C) Andrey Kuzmin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Andrey Kuzmin E<lt>chipsoid@cpan.orgE<gt>

=cut

