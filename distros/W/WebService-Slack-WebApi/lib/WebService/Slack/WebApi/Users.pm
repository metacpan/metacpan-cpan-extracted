package WebService::Slack::WebApi::Users;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    get_presence => {
        user => 'Str',
    },
    identity     => +{},
    info => {
        user => 'Str',
    },
    list         => +{},
    set_active   => +{},
    set_presence => {
        presence => 'Str',
    },
);

1;

