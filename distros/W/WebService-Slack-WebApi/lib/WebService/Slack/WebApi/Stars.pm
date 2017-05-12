package WebService::Slack::WebApi::Stars;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    list => {
        user  => { isa => 'Str', optional => 1 },
        count => { isa => 'Int', optional => 1 },
        page  => { isa => 'Int', optional => 1 },
    },
);

1;

