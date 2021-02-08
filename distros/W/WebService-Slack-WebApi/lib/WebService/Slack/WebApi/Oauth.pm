package WebService::Slack::WebApi::Oauth;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Oauth::V2;

use Class::Accessor::Lite::Lazy (
    ro_lazy => [qw/ v2 /],
);

use WebService::Slack::WebApi::Generator (
    access => {
        client_id     => 'Str',
        client_secret => 'Str',
        code          => 'Str',
        redirect_uri  => { isa => 'Str', optional => 1 },
    },
    token => {
        client_id       => 'Str',
        client_secret   => 'Str',
        code            => 'Str',
        redirect_uri    => { isa => 'Str',  optional => 1 },
        single_channel  => { isa => 'Bool', optional => 1 },
    },
);

sub _build_v2 {
    return WebService::Slack::WebApi::Oauth::V2->new(client => shift->client);
}

1;

