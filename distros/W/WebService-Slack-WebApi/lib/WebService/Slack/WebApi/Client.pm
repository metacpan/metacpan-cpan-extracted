package WebService::Slack::WebApi::Client;
use strict;
use warnings;
use utf8;

use Furl;
use JSON::XS;
use HTTP::Request::Common;
use WebService::Slack::WebApi::Exception;

use Class::Accessor::Lite::Lazy (
    new     => 1,
    rw      => [qw/ team_domain token opt /],
    ro_lazy => [qw/ ua /],
);

sub _build_ua {
    my $self = shift;
    my %opt = %{ $self->opt // +{} };
    my $env_proxy = delete $opt{env_proxy};
    my $ua = Furl->new(%opt);
    $ua->env_proxy if $env_proxy;
    return $ua;
}

sub base_url {
    my $self = shift;
    my $team_domain = $self->team_domain ? $self->team_domain . '.' : '';
    return sprintf 'https://%sslack.com/api', $team_domain;
}

sub request {
    my ($self, $path, $params) = @_;

    my $request = POST $self->base_url . $path,
        Content_Type => 'form-data',
        Content      => [
            $self->token ? (token => $self->token) : (),
            %$params,
        ];
    my $response = $self->ua->request($request);

    return decode_json $response->content if $response->is_success;

    WebService::Slack::WebApi::Exception::FailureResponse->throw(
        message  => 'request failed.',
        response => $response,
    );
}

1;

