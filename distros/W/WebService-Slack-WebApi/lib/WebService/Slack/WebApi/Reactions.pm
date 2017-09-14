package WebService::Slack::WebApi::Reactions;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    add => {
        name         => 'Str',
        channel      => { isa => 'Str', optional => 1 },
        file         => { isa => 'Str', optional => 1 },
        file_comment => { isa => 'Str', optional => 1 },
        timestamp    => { isa => 'Str', optional => 1 },
    },
    get => {
        channel      => { isa => 'Str',  optional => 1 },
        file         => { isa => 'Str',  optional => 1 },
        file_comment => { isa => 'Str',  optional => 1 },
        full         => { isa => 'Bool', optional => 1 },
        timestamp    => { isa => 'Str',  optional => 1 },
    },
    list => {
        count => { isa => 'Int',  optional => 1 },
        full  => { isa => 'Bool', optional => 1 },
        page  => { isa => 'Int',  optional => 1 },
        user  => { isa => 'Str',  optional => 1 },
    },
    remove => {
        name         => 'Str',
        channel      => { isa => 'Str', optional => 1 },
        file         => { isa => 'Str', optional => 1 },
        file_comment => { isa => 'Str', optional => 1 },
        timestamp    => { isa => 'Str', optional => 1 },
    },
);

1;

