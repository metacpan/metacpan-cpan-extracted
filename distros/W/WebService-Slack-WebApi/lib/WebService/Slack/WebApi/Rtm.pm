package WebService::Slack::WebApi::Rtm;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    connect => {
        batch_presence_aware => { isa => 'Bool', optional => 1 },
        presence_sub         => { isa => 'Bool', optional => 1 },
    },
    start => {
        batch_presence_aware => { isa => 'Bool', optional => 1 },
        mpim_aware           => { isa => 'Bool', optional => 1 },
        no_latest            => { isa => 'Bool', optional => 1 },
        no_unreads           => { isa => 'Bool', optional => 1 },
        presence_sub         => { isa => 'Bool', optional => 1 },
        simple_latest        => { isa => 'Bool', optional => 1 },
    },
);

1;

