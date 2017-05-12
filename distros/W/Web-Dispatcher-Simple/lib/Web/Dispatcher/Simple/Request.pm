package Web::Dispatcher::Simple::Request;
use strict;
use warnings;
use base qw/Plack::Request/;
use Web::Dispatcher::Simple::Response;
use Encode;
use Hash::MultiValue;

sub new_response {
    my $self = shift;
    Web::Dispatcher::Simple::Response->new(@_);
}

sub uri_for {
    my ( $self, $path, $args ) = @_;
    my $uri = $self->base;
    $uri->path($path);
    $uri->query_form(@$args) if $args;
    $uri;
}

sub decode_params {
    my $self = shift;
    $self->env->{'plack.request.query'} ||= _decode_multivalue(
        Hash::MultiValue->new( $self->uri->query_form ) );
    unless ( $self->env->{'plack.request.body'} ) {
        $self->_parse_request_body;
        $self->env->{'plack.request.body'}
            = _decode_multivalue( $self->env->{'plack.request.body'} );
    }
}

sub _decode_multivalue {
    my $hash = shift;

    my $params         = $hash->mixed;
    my $decoded_params = {};
    while ( my ( $k, $v ) = each %$params ) {
        $decoded_params->{ Encode::decode_utf8($k) }
            = ref $v eq 'ARRAY'
            ? [ map Encode::decode_utf8($_), @$v ]
            : Encode::decode_utf8($v);
    }
    return Hash::MultiValue->from_mixed(%$decoded_params);
}

1;
