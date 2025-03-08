package WebService::Slack::WebApi::Client;
use strict;
use warnings;
use utf8;

use HTTP::AnyUA;
use JSON;
use WebService::Slack::WebApi::Exception;

use Class::Accessor::Lite::Lazy (
    new     => 1,
    rw      => [qw/ team_domain token opt useragent /],
    ro_lazy => [qw/ ua /],
);

sub _build_ua {
    my $self = shift;
    my $ua;
    # Before introducing the parameter 'ua' to WebService::Slack::WebApi
    # we used Furl. So let's keep ourselves backward compatible!
    if( $self->useragent ) {
        $ua = HTTP::AnyUA->new( ua => $self->useragent );
    } else {
        # Attn. Using expression form of eval because otherwise
        # the "use" would be executed before arriving to eval.
        eval 'use Furl; 1;' or do {
            my $msg = 'Illegal parameters. Unable to use package Furl.'
                    . ' If no \'ua\' is defined, we use Furl by default';
            WebService::Slack::WebApi::Exception::IllegalParameters->throw(
                message  => $msg,
            );
        };
        my %opt = %{ $self->opt // +{} };
        my $env_proxy = delete $opt{env_proxy};
        my $furl = Furl->new(%opt);
        $furl->env_proxy if $env_proxy;
        $ua = HTTP::AnyUA->new( ua => $furl );
    }
    return $ua;
}

sub base_url {
    my $self = shift;
    my $team_domain = $self->team_domain ? $self->team_domain . '.' : '';
    return sprintf 'https://%sslack.com/api', $team_domain;
}

sub request {
    my ($self, $path, $params) = @_;

    my %headers;
    if( $self->token && $params->{'http_auth'} ) {
        my $msg = 'Illegal parameters. You have defined \'token\' but the '
                . ' method you are using defines its own HTTP Authorization header.';
        WebService::Slack::WebApi::Exception::IllegalParameters->throw(
            message  => $msg,
        );
    }
    if( $self->token ) {
        $headers{ 'Authorization' } = 'Bearer ' . $self->token;
    } elsif( $params->{'http_auth'} ) {
        $headers{ 'Authorization' } = $params->{'http_auth'};
    }
    my %options = ( headers => \%headers );
    my $response = $self->ua->post_form(
        $self->base_url . $path,
        [
            %{ $params },
        ],
        \%options,
    );
    return decode_json $response->{content} if $response->{success};

    WebService::Slack::WebApi::Exception::FailureResponse->throw(
        message  => 'request failed.',
        response => $response,
    );
}

sub request_json {
    my ($self, $path, $params) = @_;

    my %headers = ( 'Content-Type' => 'application/json' );
    if( $self->token && $params->{'http_auth'} ) {
        my $msg = 'Illegal parameters. You have defined \'token\' but the '
                . ' method you are using defines its own HTTP Authorization header.';
        WebService::Slack::WebApi::Exception::IllegalParameters->throw(
            message  => $msg,
        );
    }
    if( $self->token ) {
        $headers{ 'Authorization' } = 'Bearer ' . $self->token;
    } elsif( $params->{'http_auth'} ) {
        $headers{ 'Authorization' } = $params->{'http_auth'};
        delete $params->{'http_auth'};  # slack will not allow this in the json body
    }

    # should really add error handling here.    
    my $json_body = JSON->new->utf8(1)->pretty(0)->canonical->encode($params);
    my %options = ( headers => \%headers, content => $json_body );
    
    my $response = $self->ua->request(
        'POST',
        $self->base_url . $path,
        \%options,
    );
    return decode_json $response->{content} if $response->{success};

    WebService::Slack::WebApi::Exception::FailureResponse->throw(
        message  => 'request_json failed.',
        response => $response,
    );
}

1;

