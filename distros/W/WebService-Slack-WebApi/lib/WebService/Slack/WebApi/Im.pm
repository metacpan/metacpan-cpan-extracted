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
        latest    => { isa => 'Str',  optional => 1 },
        oldest    => { isa => 'Str',  optional => 1 },
        inclusive => { isa => 'Bool', optional => 1 },
        count     => { isa => 'Int',  optional => 1 },
    },
    list => +{},
    mark => {
        channel => 'Str',
        ts      => 'Str',
    },
    open => {
        user => 'Str',
    },
);

1;

