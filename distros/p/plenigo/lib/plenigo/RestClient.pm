package plenigo::RestClient;

=head1 NAME
 plenigo::RestClient - Only for internal usage.
=head1 SYNOPSIS
 Only for internal usage. Can contain breacking changes. DO NOT USE. 
=head1 DESCRIPTION
 plenigo::RestClient provides functionality for communication with the plenigo API. Only for internal usage. Can contain breacking changes. DO NOT USE. 
=cut

use REST::Client;
use JSON;
use Carp qw(confess);
use Crypt::JWT qw(encode_jwt);
use Data::UUID;
use Moo;
use plenigo::Ex;

our $VERSION = '0.2000';

has configuration => (
    is       => 'ro',
    required => 1
);

sub _createRestClient {
    my ($self) = @_;

    my $client = REST::Client->new({
        host    => $self->configuration->use_stage ? $self->configuration->api_host_stage : $self->configuration->api_host,
        timeout => 10,
    });
    $client->addHeader('X-plenigo-token', $self->configuration->access_token);
    $client->addHeader('Content-Type', 'application/json');
    $client->addHeader('Accept', 'application/json');

    return $client;
}

sub _checkResponse {
    my ($self, $client) = @_;

    return if $client->responseCode < 400;

    plenigo::Ex->throw({
        code         => $client->responseCode,
        message      => decode_json($client->responseContent)->{errorMessage} || 'Bad Request',
        errorDetails => decode_json($client->responseContent || '{}'),
    });
}

sub get {
    my ($self, $url_path, $query_params) = @_;

    my $client = $self->_createRestClient;
    $client->GET($self->configuration->api_url . $url_path . $client->buildQuery($query_params));
    $self->_checkResponse($client);
    return(response_code => $client->responseCode, response_content => decode_json($client->responseContent));
}

sub post {
    my ($self, $url_path, $query_params, %body) = @_;

    my $client = $self->_createRestClient;
    my $json_text = encode_json \%body;
    $client->POST($self->configuration->api_url . $url_path . $client->buildQuery($query_params), $json_text);
    $self->_checkResponse($client);
    my $responseContent;
    if (not $client->responseContent eq "") {
        $responseContent = decode_json($client->responseContent);
    }
    return(response_code => $client->responseCode, response_content => $responseContent);
}

sub put {
    my ($self, $url_path, $query_params, %body) = @_;

    my $client = $self->_createRestClient;
    my $json_text = encode_json \%body;
    $client->PUT($self->configuration->api_url . $url_path . $client->buildQuery($query_params), $json_text);
    $self->_checkResponse($client);
    my $responseContent;
    if (not $client->responseContent eq "") {
        $responseContent = decode_json($client->responseContent);
    }
    return(response_code => $client->responseCode, response_content => $responseContent);
}

sub delete {
    my ($self, $url_path, $query_params) = @_;

    my $client = $self->_createRestClient;
    $client->DELETE($self->configuration->api_url . $url_path . $client->buildQuery($query_params));
    $self->_checkResponse($client);
    my $responseContent;
    if (not $client->responseContent eq "") {
        $responseContent = decode_json($client->responseContent);
    }
    return(response_code => $client->responseCode, response_content => $responseContent);
}

1;
