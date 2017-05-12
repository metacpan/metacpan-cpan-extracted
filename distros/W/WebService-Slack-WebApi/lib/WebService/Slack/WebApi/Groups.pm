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
        name => 'Str',
    },
    create_child => {
        channel => 'Str',
    },
    history => {
        channel   => 'Str',
        latest    => { isa => 'Str',  optional => 1 },
        oldest    => { isa => 'Str',  optional => 1 },
        inclusive => { isa => 'Bool', optional => 1 },
        count     => { isa => 'Int',  optional => 1 },
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
    },
    mark => {
        channel => 'Str',
        ts      => 'Str',
    },
    open => {
        channel => 'Str'
    },
    rename => {
        channel => 'Str',
        name    => 'Str',
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

