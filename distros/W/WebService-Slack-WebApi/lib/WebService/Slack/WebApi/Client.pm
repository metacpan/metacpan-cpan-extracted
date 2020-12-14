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

    my $response = $self->ua->post_form(
        $self->base_url . $path,
        [
            $self->token ? (token => $self->token) : (),
            %{ $params },
        ],
    );
    return decode_json $response->{content} if $response->{success};

    WebService::Slack::WebApi::Exception::FailureResponse->throw(
        message  => 'request failed.',
        response => $response,
    );
}

1;

