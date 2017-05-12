package WebService::Slack::WebApi::Reactions;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    add => {
        name         => 'Str',
        file         => { isa => 'Str', optional => 1 },
        file_comment => { isa => 'Str', optional => 1 },
        channel      => { isa => 'Str', optional => 1 },
        timestamp    => { isa => 'Str', optional => 1 },
    },
    get => {
        file         => { isa => 'Str',  optional => 1 },
        file_comment => { isa => 'Str',  optional => 1 },
        channel      => { isa => 'Str',  optional => 1 },
        timestamp    => { isa => 'Str',  optional => 1 },
        full         => { isa => 'Bool', optional => 1 },
    },
    list => {
        user  => { isa => 'Str',  optional => 1 },
        full  => { isa => 'Bool', optional => 1 },
        count => { isa => 'Int',  optional => 1 },
        page  => { isa => 'Int',  optional => 1 },
    },
    remove => {
        name         => 'Str',
        file         => { isa => 'Str', optional => 1 },
        file_comment => { isa => 'Str', optional => 1 },
        channel      => { isa => 'Str', optional => 1 },
        timestamp    => { isa => 'Str', optional => 1 },
    },
);

1;

