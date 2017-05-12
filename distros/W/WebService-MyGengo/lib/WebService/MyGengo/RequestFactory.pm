package WebService::MyGengo::RequestFactory;

use Moose;
use namespace::autoclean;

BEGIN { extends 'WebService::MyGengo::Base' };

use WebService::MyGengo::Exception;

use URI;
use Digest::HMAC;
use Digest::SHA1;
use JSON qw(encode_json);

=head1 NAME

WebService::MyGengo::RequestFactory - A factory for creating myGengo API requests

=head1 DESCRIPTION

Returns various L<WebService::MyGengo::Request> objects to be sent to the API.

=head1 SYNOPSIS

    # Note: Requests are usually created automatically by WebService::MyGengo::Client
    my $req_factory = new WebService::MyGengo::RequestFactory({
        public_key      => $pubkey
        , private_key   => $privkey
        , root_uri      => $api_uri
        });

    my $req = $req_factory->new_request( $method, $endpoint, \%params );

    # Alternate constructor syntax
    my $req_factory = new WebService::MyGengo::RequestFactory(
        $pubkey
        , $privkey
        , $api_uri
        );

=head1 ATTRIBUTES

All attributes are read-only. If, for some reason, you need to generate
requests for a different keypair or root_uri, just make a new RequestFactory.

=head2 public_key (Str)

Your public API key.

=head2 private_key (Str)

Your private API key

=cut
has [qw/public_key private_key/] => (
    is          => 'ro'
    , isa       => 'Str'
    , required	=> 1
    );

=head2 root_uri (URI)

The URI to be used as the base for all API endpoints.

eg, 'http://api.sandbox.mygengo.com/v1.1'

=cut
has root_uri => (
    is			=> 'ro'
    , isa		=> 'WebService::MyGengo::URI'
    , required	=> 1
    );

=head1 METHODS
=cut

#=head2 BUILDARGS
#
#Allow arguments as a list or hashref.
#
#=cut
around BUILDARGS  => sub {
    my ( $orig, $class, $args ) = ( shift, shift, @_ );

    ref($args) eq 'HASH' and return $class->$orig(@_);

    return {
        public_key      => shift
        , private_key   => shift
        , root_uri      => shift->clone
        };
};

=head2 new_request( $request_method, $endpoint, \%params )

Returns an L<HTTP::Request> object for the given API endpoint.

=cut
sub new_request {
    my ( $self, $method, $endpoint, $params ) = ( shift, @_ );

    !( $method && $endpoint ) and WebService::MyGengo::Exception->throw({
        message => "Both an HTTP request method and API endpoint are required"
                    . " to create a request."
        });

    my $builder_method = "_build_".$method;
    my $builder = $self->can( $builder_method )
        or WebService::MyGengo::Exception->throw({ message =>
            "Cannot find builder for '"
            . $method . "' request."
            });

    my $req = $self->$builder( $method, $endpoint, $params );

    return $req;
}

sub _build_POST {
    return shift->_build_request_with_form_params( @_ );
}

sub _build_PUT {
    return shift->_build_request_with_form_params( @_ );
}

sub _build_GET {
    return shift->_build_request_with_query_params( @_ );
}

sub _build_DELETE {
    return shift->_build_request_with_query_params( @_ );
}

sub _build_request_with_form_params {
    my ( $self, $method, $endpoint, $params ) = ( shift, @_ );

    my ( $uri, $req_params ) = $self->_get_uri_and_req_params( @_ );

    $req_params->{data} = encode_json($params);

    my $request = HTTP::Request->new( $method => $uri );
    $request->push_header( 'Accept' => 'application/json; charset=utf-8' );
    $request->push_header('Content-Type' =>'application/x-www-form-urlencoded');

    # See L<HTTP::Request::Common>'s POST method. We're just using URI to
    #   format the request body for us in this case.
    $uri->query_form( $req_params );
    $request->content( $uri->query );

    return $request;
}

sub _build_request_with_query_params {
    my ( $self, $method, $endpoint, $params ) = ( shift, @_ );

    my ( $uri, $req_params ) = $self->_get_uri_and_req_params( @_ );

    # Non-POST/PUT requests need query parameters
    ref($params) eq 'HASH' and @$req_params{ keys %$params } = values %$params;
    $uri->query_form( $req_params );

    my $request = HTTP::Request->new( $method => $uri );
    $request->push_header( 'Accept' => 'application/json; charset=utf-8' );

    return $request;
}

#=head2 _get_uri_and_req_params( $method, $endpoint )
#
#Returns an array of a URI object and a hashref of request parameters
#common to all API requests.
#
#=cut
sub _get_uri_and_req_params {
    my ( $self, $method, $endpoint ) = ( shift, @_ );

    my $pubkey      = $self->public_key;
    my $privkey     = $self->private_key;
    my $uri         = $self->root_uri->clone;

    $uri->path( $uri->path . $endpoint );

    my $time = time();
    my $hmac = Digest::HMAC->new($privkey, "Digest::SHA1");
    $hmac->add($time);

    my $req_params = {
        'api_sig'   => $hmac->hexdigest
        , 'api_key' => $pubkey
        , 'ts'      => $time
        };

    return ( $uri, $req_params );
}


__PACKAGE__->meta->make_immutable();
1;

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
