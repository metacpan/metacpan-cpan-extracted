use strict;
use warnings;

use Test2::V0 -target => 'WebService::Pixela::User';

use WebService::Pixela;

my $username = 'testuser';
my $token = 'thisistoken';

my $pixela = WebService::Pixela->new(username => $username, token => $token);
my $user   = $pixela->user;

subtest 'use_methods' => sub {
    can_ok($CLASS,qw/new create client create update delete/);
};

subtest 'new' => sub {
    ok( my $obj = $CLASS->new($pixela),'create instance');
    isa_ok($user->{client}, [qw/'WebService::Pixela/], 'client is WebService::Pixela instance');
};

subtest 'use_methods_by_instance' => sub {
    can_ok($user,qw/new create client create update delete/);
};

subtest 'client_method' => sub {
    isa_ok($user->client, [qw/'WebService::Pixela/], 'client is WebService::Pixela instance');
};


subtest 'create_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request => sub {shift @_; return [@_]; }],
    );
    is(
        $user->create(),
        [ 'POST',
          'users/',
            {
                username            => $username,
                token               => $token,
                agreeTermsOfService => 'yes',
                notMinor            => 'yes',
            }
        ],
        'not input agreeTermsOfService and notMinor , default yes'
    ) ;

    is(
        $user->create(agree_terms_of_service => 'no', not_minor => 'no'),
        [
            'POST',
            'users/',
            {
                username            => $username,
                token               => $token,
                agreeTermsOfService => 'no',
                notMinor            => 'no',
            }
        ],
        'input agreeTermsOfService and notMinor'
    ) ;
};

subtest 'update_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header => sub {shift @_; return [@_]; }],
    );

    my $pixela       = WebService::Pixela->new(username => $username, token => $token);
    my $user         = $pixela->user;
    my $old_token    = $token;
    my $update_token = 'updatetoken';

    is   ($pixela->token, $old_token);
    isnt ($pixela->token, $update_token);
    is   ($user->client->token, $old_token);
    isnt ($user->client->token, $update_token);

    is(
        $user->update($update_token),
        [
            'PUT',
            "users/".$username,
            {
                newToken => $update_token,
            },
        ],
        'update token params for request_with_xuser_in_header'
    );
    is   ($pixela->token, $update_token);
    isnt ($pixela->token, $old_token);
    is   ($user->client->token, $update_token);
    isnt ($user->client->token, $old_token);
};

subtest 'deletee_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header => sub {shift @_; return [@_]; }],
    );

    my $pixela       = WebService::Pixela->new(username => $username, token => $token);
    my $user         = $pixela->user;
    is(
        $user->delete(),
        [
            'DELETE',
            "users/".$username,
            {},
        ],
        'delete method params for request_with_xuser_in_header'
    );
};

done_testing;
