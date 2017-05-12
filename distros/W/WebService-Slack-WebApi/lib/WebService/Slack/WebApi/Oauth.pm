package WebService::Slack::WebApi::Oauth;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    access => {
        client_id     => 'Str',
        client_secret => 'Str',
        code          => 'Str',
        redirect_uri  => { isa => 'Str', optional => 1 },
    },
);

1;

