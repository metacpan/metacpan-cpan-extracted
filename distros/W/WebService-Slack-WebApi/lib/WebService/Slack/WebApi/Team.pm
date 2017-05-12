package WebService::Slack::WebApi::Team;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    access_logs => {
        count => { isa => 'Int', optional => 1 },
        page  => { isa => 'Int', optional => 1 },
    },
    info => {},
);

1;

