package WebService::Slack::WebApi::Oauth::V2;
use strict;
use warnings;
use utf8;
use feature qw/ state /;

use MIME::Base64 qw/ encode_base64 /;

use parent 'WebService::Slack::WebApi::Base';

# override
sub base_name { 'oauth.v2' }

sub access {
    # Attn. client_id and client_secret are optional parameters for Slack
    # because Slack makes it possible to authenticate either
    # by using them or by setting an HTTP Auth header.
    # https://api.slack.com/methods/oauth.v2.access
    # But here we make the parameters mandatory because
    # they are needed to call this method in any case.
    state $rule = Data::Validator->new(
        code          => 'Str',
        client_id     => { isa => 'Str', optional => 0 },
        client_secret => { isa => 'Str', optional => 0 },
        redirect_uri  => { isa => 'Str', optional => 1 },
    )->with('Method');
    my ($self, $args) = $rule->validate(@_);

    my $t = encode_base64( $args->{'client_id'} . q{:} . $args->{'client_secret'}, q{} );
    my $basic_auth = 'Basic ' . $t;
    return $self->request('access', {
            code => $args->{'code'},
            redirect_uri => $args->{'redirect_uri'},
            http_auth => $basic_auth,
        }
    );
}

1;

