package WebService::Slack::WebApi::Bots;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    info => {
        bot => 'Str',
    },
);

1;

