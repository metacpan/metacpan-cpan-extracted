use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::MockObject;
use Test::MockObject::Extends;

use WebService::SendBird;

use JSON::MaybeXS ();

subtest 'Creating API client' => sub {
    my @tests = ([{api_token => 1}, qr/^Missing required argument: app_id or api_url/], [{app_id => 1}, qr/^Missing required argument: api_token/],);

    for my $test_case (@tests) {
        my $err = exception { WebService::SendBird->new(%{$test_case->[0]}) };
        like $err, $test_case->[1], "Got Expected error";
    }

    ok(
        WebService::SendBird->new(
            api_token => 1,
            app_id    => 1
        ),
        'Api Client created'
    );
    ok(
        WebService::SendBird->new(
            api_token => 1,
            api_url   => 'http://sendbird.com/api/v3'
        ),
        'Api Client created'
    );
};

subtest 'Getters methods' => sub {
    my $api = WebService::SendBird->new(
        api_token => 'TestToken',
        app_id    => 'TestAppID',
    );

    is $api->api_token, 'TestToken',                             'Get api_token';
    is $api->app_id,    'TestAppID',                             'Get app_id';
    is $api->api_url,   'https://api-TestAppID.sendbird.com/v3', 'Get generated api url';

    $api = WebService::SendBird->new(
        api_token => 'TestToken',
        api_url   => 'http://sendbird.com/api/v3',
    );
    is $api->api_token, 'TestToken',                  'Get api_token';
    is $api->app_id,    undef,                        'Get app_id';
    is $api->api_url,   'http://sendbird.com/api/v3', 'Get api url which was passed';

    $api = WebService::SendBird->new(
        api_token => 'TestToken',
        app_id    => 'TestAppID',
        api_url   => 'http://sendbird.com/api/v3',
    );
    is $api->api_token, 'TestToken',                  'Get api_token';
    is $api->app_id,    'TestAppID',                  'Get app_id';
    is $api->api_url,   'http://sendbird.com/api/v3', 'Get api url which was passed';
};

subtest 'Making request to api' => sub {
    my $mock_ua = Test::MockObject->new();
    $mock_ua->mock(
        build_tx => sub {
            my ($ua, $method, $url, $http_headers, $data_type, $data) = @_;
            return +{
                method    => $method,
                url       => $url,
                headers   => $http_headers,
                data_type => $data_type,
                data      => $data,
            };
        });
    $mock_ua->mock(
        start => sub {
            my ($ua, $resp_data) = @_;

            my $mock_result = Test::MockObject->new();
            $mock_result->mock(code => sub { 200 });
            $mock_result->mock(json => sub { $resp_data });

            my $mock_resp = Test::MockObject->new();
            $mock_resp->mock(result => sub { $mock_result });

            return $mock_resp;
        });

    my $api = WebService::SendBird->new(
        api_token => 'TestToken',
        app_id    => 'TestAppID',
        ua        => $mock_ua,
    );

    my $resp = $api->request(
        GET => "users/testuser",
        {extra_param => 1});

    my $expected_get_resp = {
        url       => 'https://api-TestAppID.sendbird.com/v3/users/testuser',
        method    => 'GET',
        data_type => 'form',
        data      => {extra_param => 1},
        headers   => {
            'Content-Type' => 'application/json, charset=utf8',
            'Api-Token'    => 'TestToken',
        },
    };
    is_deeply($resp, $expected_get_resp, 'We pass correct params for get request');

    $resp = $api->request(
        PUT => "users/testuser",
        {extra_param => 1});

    my $expected_put_resp = {
        url       => 'https://api-TestAppID.sendbird.com/v3/users/testuser',
        method    => 'PUT',
        data_type => 'json',
        data      => {extra_param => 1},
        headers   => {
            'Content-Type' => 'application/json, charset=utf8',
            'Api-Token'    => 'TestToken',
        },
    };
    is_deeply($resp, $expected_put_resp, 'We pass correct params for put request');
};

subtest 'Creating user' => sub {
    my $api = WebService::SendBird->new(
        api_token => 'TestToken',
        app_id    => 'TestAppID',
    );

    my $user_id     = 'UserID1';
    my $nickname    = 'TestUser';
    my $profile_url = undef;

    $api = Test::MockObject::Extends->new($api);
    my $request;
    $api->mock(
        request => sub {
            my ($api, $method, $path, $params) = @_;

            $request = {
                method => $method,
                path   => $path,
                params => $params,
            };

            return +{
                user_id     => $user_id,
                nickname    => $nickname,
                profile_url => $profile_url,
            };
        });

    my $err = exception { $api->create_user(user_id => $user_id, nickname => $nickname) };
    like $err, qr{^profile_url is missed}, "Got Expected error";

    my $err1 = exception { $api->create_user(nickname => $nickname, profile_url => $profile_url) };
    like $err1, qr{^user_id is missed}, "Got Expected error";

    my $err2 = exception { $api->create_user(user_id => $user_id, profile_url => $profile_url) };
    like $err2, qr{^nickname is missed}, "Got Expected error";

    my $user = $api->create_user(
        user_id     => $user_id,
        nickname    => $nickname,
        profile_url => $profile_url,
    );

    isa_ok($user, 'WebService::SendBird::User');

    my $expected_request = +{
        method => 'POST',
        path   => 'users',
        params => {
            user_id     => $user_id,
            nickname    => $nickname,
            profile_url => $profile_url,
        }};

    is_deeply($request, $expected_request, 'Send expected request');
};

subtest 'View user' => sub {
    my $api = WebService::SendBird->new(
        api_token => 'TestToken',
        app_id    => 'TestAppID',
    );

    my $user_id     = 'UserID1';
    my $nickname    = 'TestUser';
    my $profile_url = undef;

    $api = Test::MockObject::Extends->new($api);
    my $request;
    $api->mock(
        request => sub {
            my ($api, $method, $path, $params) = @_;

            $request = {
                method => $method,
                path   => $path,
                params => $params,
            };

            return +{
                user_id     => $user_id,
                nickname    => $nickname,
                profile_url => $profile_url,
            };
        });

    my $err1 = exception { $api->view_user() };
    like $err1, qr{^user_id is missed}, "Got Expected error";

    my $user = $api->view_user(
        user_id              => $user_id,
        include_unread_count => 'true',
    );

    isa_ok($user, 'WebService::SendBird::User');

    my $expected_request = +{
        method => 'GET',
        path   => 'users/' . $user_id,
        params => {
            include_unread_count => 'true',
        }};

    is_deeply($request, $expected_request, 'Send expected request');
};

subtest 'Creating Group Chat' => sub {
    my $api = WebService::SendBird->new(
        api_token => 'TestToken',
        app_id    => 'TestAppID',
    );

    my $channel_url = 'TestChan';

    $api = Test::MockObject::Extends->new($api);
    my $request;
    $api->mock(
        request => sub {
            my ($api, $method, $path, $params) = @_;

            $request = {
                method => $method,
                path   => $path,
                params => $params,
            };

            return +{
                channel_url => $channel_url,
            };
        });

    my $group_chat = $api->create_group_chat(channel_url => $channel_url);

    isa_ok($group_chat, 'WebService::SendBird::GroupChat');

    my $expected_request = +{
        method => 'POST',
        path   => 'group_channels',
        params => {
            channel_url => $channel_url,
        },
    };

    is_deeply($request, $expected_request, 'Send expected request');
};

subtest 'View Group Chat' => sub {
    my $api = WebService::SendBird->new(
        api_token => 'TestToken',
        app_id    => 'TestAppID',
    );

    my $channel_url = 'TestChan';

    $api = Test::MockObject::Extends->new($api);
    my $request;
    $api->mock(
        request => sub {
            my ($api, $method, $path, $params) = @_;

            $request = {
                method => $method,
                path   => $path,
                params => $params,
            };

            return +{
                channel_url => $channel_url,
            };
        });

    my $err1 = exception { $api->view_group_chat() };
    like $err1, qr{^channel_url is missed}, "Got Expected error";

    my $group_chat = $api->view_group_chat(
        channel_url => $channel_url,
        show_member => JSON::MaybeXS::true,
    );

    isa_ok($group_chat, 'WebService::SendBird::GroupChat');

    my $expected_request = +{
        method => 'GET',
        path   => "group_channels/$channel_url",
        params => {
            show_member => JSON::MaybeXS::true,
        },
    };

    is_deeply($request, $expected_request, 'Send expected request');
};

subtest 'Freeze Group Chat' => sub {

    my $api = WebService::SendBird->new(
        api_token => 'TestToken',
        app_id    => 'TestAppID',
    );

    my $channel_url = 'TestChan';

    $api = Test::MockObject::Extends->new($api);
    my $request;
    $api->mock(
        request => sub {
            my ($api, $method, $path, $params) = @_;

            $request = {
                method => $method,
                path   => $path,
                params => $params,
            };
            print STDERR "freeze in mock request is $params->{freeze}\n";
            return +{
                channel_url => $channel_url,
                freeze      => $params->{freeze},
            };
        });

    my $group_chat = $api->view_group_chat(
        channel_url => $channel_url,
    );

    is_deeply $group_chat->set_freeze(1)->freeze, JSON::MaybeXS::true, 'set freeze';
    is_deeply(
        $request,
        {
            method => 'PUT',
            path   => "group_channels/$channel_url/freeze",
            params => {freeze => JSON::MaybeXS::true},
        },
        'expected request'
    );

    is_deeply $group_chat->set_freeze(0)->freeze, JSON::MaybeXS::false, 'unset freeze';

    is_deeply(
        $request,
        {
            method => 'PUT',
            path   => "group_channels/$channel_url/freeze",
            params => {freeze => JSON::MaybeXS::false},
        },
        'expected request'
    );

};

done_testing()
