package WebService::Slack::WebApi::Search;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    all => {
        query     => 'Str',
        count     => { isa => 'Int',  optional => 1 },
        highlight => { isa => 'Bool', optional => 1 },
        page      => { isa => 'Int',  optional => 1 },
        sort      => { isa => 'Str',  optional => 1 },
        sort_dir  => { isa => 'Str',  optional => 1 },
    },
    files => {
        query     => 'Str',
        count     => { isa => 'Int',  optional => 1 },
        highlight => { isa => 'Bool', optional => 1 },
        page      => { isa => 'Int',  optional => 1 },
        sort      => { isa => 'Str',  optional => 1 },
        sort_dir  => { isa => 'Str',  optional => 1 },
    },
    messages => {
        query     => 'Str',
        count     => { isa => 'Int',  optional => 1 },
        highlight => { isa => 'Bool', optional => 1 },
        page      => { isa => 'Int',  optional => 1 },
        sort      => { isa => 'Str',  optional => 1 },
        sort_dir  => { isa => 'Str',  optional => 1 },
    },
);

1;

