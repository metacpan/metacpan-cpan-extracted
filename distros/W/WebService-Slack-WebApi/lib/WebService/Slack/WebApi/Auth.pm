package WebService::Slack::WebApi::Auth;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    revoke => {
        test => { isa => 'Bool', optional => 1 },
    },
    test => +{},
);

1;

