package WebService::Slack::WebApi::Team;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    access_logs => {
        before => { isa => 'Int', optional => 1 },
        count  => { isa => 'Int', optional => 1 },
        page   => { isa => 'Int', optional => 1 },
    },
    billable_info => {
        user => { isa => 'Str', optional => 1 },
    },
    info => +{},
    integration_logs => {
        app_id      => { isa => 'Str', optional => 1 },
        change_type => { isa => 'Str', optional => 1 },
        count       => { isa => 'Int', optional => 1 },
        page        => { isa => 'Int', optional => 1 },
        service_id  => { isa => 'Str', optional => 1 },
        user        => { isa => 'Str', optional => 1 },
    },
);

1;

