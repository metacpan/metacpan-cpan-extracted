package WebService::Slack::WebApi::Users::Profile;
use strict;
use warnings;
use utf8;
use feature qw/state/;

use parent 'WebService::Slack::WebApi::Base';

use JSON;

use WebService::Slack::WebApi::Generator (
    get => {
        include_labels => { isa => 'Bool', optional => 1 },
        user           => { isa => 'Str',  optional => 1 },
    },
);

# override
sub base_name { 'users.profile' }

sub set {
    state $rule = Data::Validator->new(
        name    => { isa => 'Str',     optional => 1 },
        profile => { isa => 'HashRef', optional => 1 },
        user    => { isa => 'Str',     optional => 1 },
        value   => { isa => 'Str',     optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{profile} = encode_json $args->{profile} if exists $args->{profile};
    return $self->request('set', { %$args, %extra });
}

1;

