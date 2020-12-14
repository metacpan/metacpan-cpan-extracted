package WebService::Slack::WebApi::Conversations;
use strict;
use warnings;
use utf8;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    archive => {
        channel => 'Str',
    },
    close => {
        channel => 'Str',
    },
    create => {
        name => 'Str',
        is_private => { isa => 'Bool', optional => 1 },
        user_ids   => { isa => 'Str',  optional => 1 },
    },
    history => {
        channel   => 'Str',
        cursor    => { isa => 'Str',  optional => 1 },
        inclusive => { isa => 'Bool', optional => 1 },
        latest    => { isa => 'Str',  optional => 1 },
        oldest    => { isa => 'Str',  optional => 1 },
    },
    info => {
        channel => 'Str',
        include_locale => { isa => 'Bool', optional => 1 },
    },
    invite => {
        channel => 'Str',
        user    => 'Str',
    },
    join => {
        channel => 'Str',
    },
    kick => {
        channel => 'Str',
        user    => 'Str',
    },
    leave => {
        channel => 'Str',
    },
    list => {
        cursor           => { isa => 'Str',  optional => 1 },
        exclude_archived => { isa => 'Bool', optional => 1 },
        limit            => { isa => 'Int',  optional => 1 },
        types            => { isa => 'Str',  optional => 1 }, 
    },
    members => {
        channel => 'Str',
        cursor  => { isa => 'Str',  optional => 1 },
        limit   => { isa => 'Int',  optional => 1 },
    },
    open => {
        channel   => { isa => 'Str',  optional => 1 },
        return_im => { isa => 'Bool', optional => 1 },
        users     => { isa => 'Str',  optional => 1 },
    },
    rename => {
        channel  => 'Str',
        name     => 'Str',
    },
    replies => {
        channel   => 'Str',
        ts        => 'Str',
        cursor    => { isa => 'Str',  optional => 1 },
        inclusive => { isa => 'Bool', optional => 1 },
        latest    => { isa => 'Str',  optional => 1 },
        limit     => { isa => 'Int',  optional => 1 },
        oldest    => { isa => 'Str',  optional => 1 },
    },
    set_purpose => {
        channel => 'Str',
        purpose => 'Str',
    },
    set_topic => {
        channel => 'Str',
        topic   => 'Str',
    },
    unarchive => {
        channel => 'Str',
    },
);

1;

