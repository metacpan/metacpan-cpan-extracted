package WebService::Slack::WebApi::Migration;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    exchange => {
        users => 'Str',
        to_old => { isa => 'Bool', optional => 1 }, 
    },
);

1;

