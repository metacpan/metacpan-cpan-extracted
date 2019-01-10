package WebService::Slack::WebApi::Dnd;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    endDnd => {
    },
    endSnooze => {
    },
    info => {
        user => 'Str',
    },
    setSnooze => {
        num_minutes => 'Int',
    },
    teamInfo => {
        users => 'Str',
    },
);

1;

