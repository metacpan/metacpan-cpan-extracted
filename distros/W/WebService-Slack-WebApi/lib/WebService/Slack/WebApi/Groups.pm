package WebService::Slack::WebApi::Groups;
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
        name     => 'Str',
        validate => { isa => 'Bool', optional => 1 },
    },
    create_child => {
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
    info => {
        channel => 'Str',
    },
    invite => {
        channel => 'Str',
        user    => 'Str',
    },
    kick => {
        channel => 'Str',
        user    => 'Str',
    },
    leave => {
        channel => 'Str',
    },
    list => {
        exclude_archived => { isa => 'Bool', optional => 1 },
        exclude_members  => { isa => 'Bool', optional => 1 },
    },
    mark => {
        channel => 'Str',
        ts      => 'Str',
    },
    open => {
        channel => 'Str'
    },
    rename => {
        channel  => 'Str',
        name     => 'Str',
        validate => { isa => 'Bool', optional => 1 },
    },
    replies => {
        channel   => 'Str',
        thread_ts => 'Str',
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

