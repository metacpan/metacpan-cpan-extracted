package WebService::Slack::WebApi::Pins;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    add => {
        channel      => 'Str',
        file         => { isa => 'Str', optional => 1 },
        file_comment => { isa => 'Str', optional => 1 },
        timestamp    => { isa => 'Str', optional => 1 },
    },
    list => {
        channel => 'Str',
    },
    remove => {
        channel      => 'Str',
        file         => { isa => 'Str', optional => 1 },
        file_comment => { isa => 'Str', optional => 1 },
        timestamp    => { isa => 'Str', optional => 1 },
    },
);

1;
