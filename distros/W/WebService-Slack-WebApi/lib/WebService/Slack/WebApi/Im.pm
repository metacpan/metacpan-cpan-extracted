package WebService::Slack::WebApi::Im;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    close => {
        channel => 'Str',
    },
    history => {
        channel   => 'Str',
        count     => { isa => 'Int',  optional => 1 },
        inclusive => { isa => 'Bool', optional => 1 },
        latest    => { isa => 'Str',  optional => 1 },
        oldest    => { isa => 'Str',  optional => 1 },
        unreads   => { isa => 'Bool', optional => 1 },
    },
    list => {
        cursor => { isa => 'Str',  optional => 1 },
        limit  => { isa => 'Int',  optional => 1 },
    },
    mark => {
        channel => 'Str',
        ts      => 'Str',
    },
    open => {
        user      => 'Str',
        return_im => { isa => 'Bool', optional => 1 },
    },
    replies => {
        channel   => 'Str',
        thread_ts => 'Str',
    },
);

1;

