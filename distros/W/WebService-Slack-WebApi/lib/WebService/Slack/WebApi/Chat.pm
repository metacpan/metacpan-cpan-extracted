package WebService::Slack::WebApi::Chat;
use strict;
use warnings;
use utf8;
use feature qw/state/;

use parent 'WebService::Slack::WebApi::Base';

use JSON;
use WebService::Slack::WebApi::Generator (
    delete => {
        channel => 'Str',
        ts      => 'Str',
        as_user => { isa => 'Bool', optional => 1 },
    },
    me_message => {
        channel => 'Str',
        text    => 'Str',
    },
    unfurl => {
        channel            => 'Str',
        ts                 => 'Str',
        unfurls            => 'Str',
        user_auth_message  => { isa => 'Str',  optional => 1 },
        user_auth_required => { isa => 'Bool', optional => 1 },
        user_auth_url      => { isa => 'Str',  optional => 1 },
    },
);

sub post_ephemeral {
    state $rule = Data::Validator->new(
        channel      => 'Str',
        text         => { isa => 'Str',      optional => 1 },
        user         => 'Str',
        as_user      => { isa => 'Bool',     optional => 1 },
        attachments  => { isa => 'ArrayRef', optional => 1 },
        link_names   => { isa => 'Bool',     optional => 1 },
        parse        => { isa => 'Str',      optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{attachments} = encode_json $args->{attachments} if exists $args->{attachments};
    return $self->request('postEphemeral', {%$args, %extra});
}

sub post_message {
    state $rule = Data::Validator->new(
        channel         => 'Str',
        text            => { isa => 'Str',      optional => 1 },
        as_user         => { isa => 'Bool',     optional => 1 },
        attachments     => { isa => 'ArrayRef', optional => 1 },
        icon_emoji      => { isa => 'Str',      optional => 1 },
        icon_url        => { isa => 'Str',      optional => 1 },
        link_names      => { isa => 'Bool',     optional => 1 },
        parse           => { isa => 'Str',      optional => 1 },
        reply_broadcast => { isa => 'Bool',     optional => 1 },
        thread_ts       => { isa => 'Str',      optional => 1 },
        unfurl_links    => { isa => 'Bool',     optional => 1 },
        unfurl_media    => { isa => 'Bool',     optional => 1 },
        username        => { isa => 'Str',      optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{attachments} = encode_json $args->{attachments} if exists $args->{attachments};
    return $self->request('postMessage', {%$args, %extra});
}

sub update {
    state $rule = Data::Validator->new(
        channel     => 'Str',
        text        => { isa => 'Str',      optional => 1 },
        ts          => 'Str',
        as_user     => { isa => 'Bool',     optional => 1 },
        attachments => { isa => 'ArrayRef', optional => 1 },
        link_names  => { isa => 'Bool',     optional => 1 },
        parse       => { isa => 'Str',      optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{attachments} = encode_json $args->{attachments} if exists $args->{attachments};
    return $self->request('update', {%$args, %extra});
}

sub schedule_message {
    state $rule = Data::Validator->new(
        channel         => 'Str',
        post_at         => 'Int',
        text            => { isa => 'Str',      optional => 1 },
        as_user         => { isa => 'Bool',     optional => 1 },
        attachments     => { isa => 'ArrayRef', optional => 1 },
        blocks          => { isa => 'ArrayRef', optional => 1 },
        icon_emoji      => { isa => 'Str',      optional => 1 },
        icon_url        => { isa => 'Str',      optional => 1 },
        link_names      => { isa => 'Bool',     optional => 1 },
        markdown_text   => { isa => 'Str',      optional => 1 },
        metadata        => { isa => 'Str',      optional => 1 },
        parse           => { isa => 'Str',      optional => 1 },
        reply_broadcast => { isa => 'Bool',     optional => 1 },
        thread_ts       => { isa => 'Str',      optional => 1 },
        unfurl_links    => { isa => 'Bool',     optional => 1 },
        unfurl_media    => { isa => 'Bool',     optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{attachments} = encode_json $args->{attachments} if exists $args->{attachments};
    $args->{blocks}      = encode_json $args->{blocks} if exists $args->{blocks};
    return $self->request('scheduleMessage', {%$args, %extra});
}

sub delete_scheduled_message {
    state $rule = Data::Validator->new(
        channel              => 'Str',
        scheduled_message_id => 'Str',
        as_user              => { isa => 'Bool',     optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    return $self->request('deleteScheduledMessage', {%$args, %extra});
}

1;

