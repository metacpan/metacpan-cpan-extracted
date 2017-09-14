package WebService::Slack::WebApi::Users;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    delete_photo => +{},
    get_presence => {
        user => 'Str',
    },
    identity => +{},
    info => {
        user => 'Str',
    },
    list => {
        cursor   => { isa => 'Str',  optional => 1 },
        limit    => { isa => 'Int',  optional => 1 },
        presence => { isa => 'Bool', optional => 1 },
    },
    set_active => +{},
    # set_photo => +{}, # FIXME: implement. https://github.com/mihyaeru21/p5-WebService-Slack-WebApi/issues/15
    set_presence => {
        presence => 'Str',
    },
);

1;

