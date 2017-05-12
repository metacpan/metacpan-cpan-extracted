package WebService::Slack::WebApi::Chat;
use strict;
use warnings;
use utf8;
use feature qw/state/;

use parent 'WebService::Slack::WebApi::Base';

use JSON::XS;
use WebService::Slack::WebApi::Generator (
    delete => {
        ts      => 'Str',
        channel => 'Str',
    },
    update => {
        ts      => 'Str',
        channel => 'Str',
        text    => 'Str',
    },
);

sub post_message {
    state $rule = Data::Validator->new(
        channel      => 'Str',
        text         => { isa => 'Str',      optional => 1 },
        username     => { isa => 'Str',      optional => 1 },
        as_user      => { isa => 'Bool',     optional => 1 },
        parse        => { isa => 'Str',      optional => 1 },
        link_names   => { isa => 'Bool',     optional => 1 },
        attachments  => { isa => 'ArrayRef', optional => 1 },
        unfurl_links => { isa => 'Str',      optional => 1 },
        unfurl_media => { isa => 'Str',      optional => 1 },
        icon_url     => { isa => 'Str',      optional => 1 },
        icon_emoji   => { isa => 'Str',      optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{attachments} = encode_json $args->{attachments} if exists $args->{attachments};
    return $self->request('postMessage', {%$args, %extra});
}

1;

