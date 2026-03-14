use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON::MaybeXS qw(decode_json encode_json);
use HTTP::Request;

use WWW::Zitadel::Management;

{
    package Local::Response;

    sub new {
        my ($class, %args) = @_;
        bless \%args, $class;
    }

    sub is_success      { $_[0]->{is_success} }
    sub status_line     { $_[0]->{status_line} }
    sub decoded_content { $_[0]->{decoded_content} // '' }
}

{
    package Local::MgmtUA;

    sub new {
        my ($class, %args) = @_;
        bless {
            queue    => $args{queue} || [],
            requests => [],
        }, $class;
    }

    sub requests { $_[0]->{requests} }

    sub request {
        my ($self, $req) = @_;
        push @{ $self->{requests} }, $req;
        my $res = shift @{ $self->{queue} };
        die "No mocked response available\n" unless $res;
        return $res;
    }
}

{
    package Local::Recorder;

    use Moo;
    extends 'WWW::Zitadel::Management';

    has calls => (
        is      => 'rw',
        default => sub { [] },
    );

    sub _request {
        my ($self, $method, $path, $body) = @_;
        push @{ $self->calls }, [ $method, $path, $body ];
        return { ok => JSON::MaybeXS::true };
    }
}

sub _success_json {
    my ($data) = @_;
    return Local::Response->new(
        is_success      => 1,
        status_line     => '200 OK',
        decoded_content => encode_json($data),
    );
}

# Base URL normalization and request metadata.
{
    my $ua = Local::MgmtUA->new(
        queue => [ _success_json({ ok => 1 }) ],
    );

    my $mgmt = WWW::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com///',
        token    => 'pat-token',
        ua       => $ua,
    );

    is $mgmt->_api_base, 'https://zitadel.example.com/management/v1', '_api_base trims trailing slashes';

    my $res = $mgmt->_post('/users/_search', { query => { limit => 1 } });
    is $res->{ok}, 1, '_request returns decoded JSON payload';

    my $req = $ua->requests->[0];
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'POST', 'request method set';
    is $req->uri->as_string, 'https://zitadel.example.com/management/v1/users/_search', 'request URL includes API base';
    is $req->header('Authorization'), 'Bearer pat-token', 'Authorization header set';
    is $req->header('Accept'), 'application/json', 'Accept header set';
    is $req->header('Content-Type'), 'application/json', 'Content-Type set for request with body';

    my $payload = decode_json($req->content);
    is $payload->{query}{limit}, 1, 'request body encoded as JSON';
}

# Empty successful response falls back to empty hashref.
{
    my $ua = Local::MgmtUA->new(
        queue => [ Local::Response->new(is_success => 1, status_line => '204 No Content', decoded_content => '') ],
    );

    my $mgmt = WWW::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
        ua       => $ua,
    );

    my $res = $mgmt->_delete('/users/u1');
    is_deeply $res, {}, 'empty response returns empty hashref';
}

# Error response includes API message when available.
{
    my $ua = Local::MgmtUA->new(
        queue => [ Local::Response->new(
            is_success      => 0,
            status_line     => '400 Bad Request',
            decoded_content => encode_json({ message => 'invalid input' }),
        ) ],
    );

    my $mgmt = WWW::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
        ua       => $ua,
    );

    throws_ok { $mgmt->_get('/users/x') }
        qr/API error: 400 Bad Request - invalid input/,
        'error includes message from API payload';
}

# Error response without parsable JSON still reports status line.
{
    my $ua = Local::MgmtUA->new(
        queue => [ Local::Response->new(
            is_success      => 0,
            status_line     => '503 Service Unavailable',
            decoded_content => '<html>upstream down</html>',
        ) ],
    );

    my $mgmt = WWW::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
        ua       => $ua,
    );

    throws_ok { $mgmt->_get('/users/x') }
        qr/API error: 503 Service Unavailable/,
        'error without JSON payload still includes status';
}

# High-level methods produce expected paths and payload shapes.
{
    my $mgmt = Local::Recorder->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
    );

    $mgmt->list_users(offset => 5, limit => 20, queries => [ { foo => 'bar' } ]);
    my ($method1, $path1, $body1) = @{ $mgmt->calls->[0] };
    is $method1, 'POST', 'list_users uses POST';
    is $path1, '/users/_search', 'list_users path';
    is $body1->{query}{offset}, 5, 'list_users offset mapped';
    is $body1->{query}{limit}, 20, 'list_users limit mapped';
    ok $body1->{query}{asc}, 'list_users asc defaults to true';

    $mgmt->create_human_user(
        user_name  => 'alice',
        first_name => 'Alice',
        last_name  => 'Smith',
        email      => 'alice@example.com',
    );

    my ($method2, $path2, $body2) = @{ $mgmt->calls->[1] };
    is $method2, 'POST', 'create_human_user uses POST';
    is $path2, '/users/human', 'create_human_user path';
    is $body2->{userName}, 'alice', 'username mapped';
    is $body2->{profile}{displayName}, 'Alice Smith', 'display name defaults to first + last name';

    $mgmt->create_oidc_app(
        'project-1',
        name          => 'Web App',
        redirect_uris => ['https://app.example.com/cb'],
    );

    my ($method3, $path3, $body3) = @{ $mgmt->calls->[2] };
    is $method3, 'POST', 'create_oidc_app uses POST';
    is $path3, '/projects/project-1/apps/oidc', 'create_oidc_app path';
    is_deeply $body3->{redirectUris}, ['https://app.example.com/cb'], 'redirect URIs mapped';
    is $body3->{appType}, 'OIDC_APP_TYPE_WEB', 'default app type is set';
}

# Remaining high-level methods map to expected paths and payloads.
{
    my $mgmt = Local::Recorder->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
    );

    $mgmt->get_user('u1');
    $mgmt->update_user('u1', first_name => 'A', last_name => 'B');
    $mgmt->deactivate_user('u1');
    $mgmt->reactivate_user('u1');
    $mgmt->delete_user('u1');

    $mgmt->list_projects;
    $mgmt->get_project('p1');
    $mgmt->update_project('p1', name => 'Renamed');
    $mgmt->delete_project('p1');

    $mgmt->list_apps('p1');
    $mgmt->get_app('p1', 'a1');
    $mgmt->update_oidc_app('p1', 'a1', redirect_uris => ['https://example/cb']);
    $mgmt->delete_app('p1', 'a1');

    $mgmt->get_org;
    $mgmt->add_project_role('p1', role_key => 'viewer');
    $mgmt->list_project_roles('p1');
    $mgmt->create_user_grant(
        user_id    => 'u1',
        project_id => 'p1',
        role_keys  => ['viewer'],
    );
    $mgmt->list_user_grants(limit => 3);

    is_deeply $mgmt->calls->[0], ['GET', '/users/u1', undef], 'get_user path';
    is $mgmt->calls->[1][0], 'PUT', 'update_user uses PUT';
    is $mgmt->calls->[1][1], '/users/u1/profile', 'update_user path';
    is $mgmt->calls->[1][2]{firstName}, 'A', 'update_user maps first name';
    is_deeply $mgmt->calls->[2], ['POST', '/users/u1/_deactivate', {}], 'deactivate_user path';
    is_deeply $mgmt->calls->[3], ['POST', '/users/u1/_reactivate', {}], 'reactivate_user path';
    is_deeply $mgmt->calls->[4], ['DELETE', '/users/u1', undef], 'delete_user path';

    is $mgmt->calls->[5][1], '/projects/_search', 'list_projects path';
    is $mgmt->calls->[5][2]{query}{limit}, 100, 'list_projects default limit';
    is_deeply $mgmt->calls->[6], ['GET', '/projects/p1', undef], 'get_project path';
    is $mgmt->calls->[7][1], '/projects/p1', 'update_project path';
    is $mgmt->calls->[7][2]{name}, 'Renamed', 'update_project name mapped';
    is_deeply $mgmt->calls->[8], ['DELETE', '/projects/p1', undef], 'delete_project path';

    is $mgmt->calls->[9][1], '/projects/p1/apps/_search', 'list_apps path';
    is_deeply $mgmt->calls->[10], ['GET', '/projects/p1/apps/a1', undef], 'get_app path';
    is $mgmt->calls->[11][1], '/projects/p1/apps/a1/oidc_config', 'update_oidc_app path';
    is_deeply $mgmt->calls->[12], ['DELETE', '/projects/p1/apps/a1', undef], 'delete_app path';

    is_deeply $mgmt->calls->[13], ['GET', '/orgs/me', undef], 'get_org path';
    is $mgmt->calls->[14][1], '/projects/p1/roles', 'add_project_role path';
    is $mgmt->calls->[14][2]{displayName}, 'viewer', 'add_project_role display_name defaults to role_key';
    is $mgmt->calls->[15][1], '/projects/p1/roles/_search', 'list_project_roles path';
    is $mgmt->calls->[16][1], '/users/u1/grants', 'create_user_grant path';
    is_deeply $mgmt->calls->[16][2]{roleKeys}, ['viewer'], 'create_user_grant role keys mapped';
    is $mgmt->calls->[17][1], '/users/grants/_search', 'list_user_grants path';
    is $mgmt->calls->[17][2]{query}{limit}, 3, 'list_user_grants limit mapped';
}

# Additional required-argument checks.
{
    my $mgmt = WWW::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
        ua       => Local::MgmtUA->new(queue => [ _success_json({ ok => 1 }) ]),
    );

    throws_ok {
        $mgmt->create_human_user(
            user_name  => 'alice',
            first_name => 'Alice',
            email      => 'alice@example.com',
        );
    } qr/last_name required/, 'create_human_user validates last_name';

    throws_ok {
        $mgmt->create_oidc_app('project-1', name => 'App');
    } qr/redirect_uris required/, 'create_oidc_app validates redirect_uris';

    throws_ok {
        $mgmt->add_project_role('project-1', display_name => 'Admin');
    } qr/role_key required/, 'add_project_role validates role_key';

    throws_ok {
        $mgmt->create_user_grant(project_id => 'p1', role_keys => ['admin']);
    } qr/user_id required/, 'create_user_grant validates user_id';
}

# update_oidc_app maps snake_case keys to camelCase.
{
    my $mgmt = Local::Recorder->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
    );

    $mgmt->update_oidc_app('p1', 'a1',
        redirect_uris           => ['https://app.example.com/cb'],
        response_types          => ['OIDC_RESPONSE_TYPE_CODE'],
        grant_types             => ['OIDC_GRANT_TYPE_AUTHORIZATION_CODE'],
        app_type                => 'OIDC_APP_TYPE_WEB',
        auth_method             => 'OIDC_AUTH_METHOD_TYPE_BASIC',
        post_logout_uris        => ['https://app.example.com/logout'],
        dev_mode                => JSON::MaybeXS::false,
        access_token_type       => 'OIDC_TOKEN_TYPE_BEARER',
        id_token_role_assertion => JSON::MaybeXS::true,
        additional_origins      => ['https://app2.example.com'],
    );

    my ($method, $path, $body) = @{ $mgmt->calls->[0] };
    is $method, 'PUT', 'update_oidc_app uses PUT';
    is $path, '/projects/p1/apps/a1/oidc_config', 'update_oidc_app path';
    is_deeply $body->{redirectUris}, ['https://app.example.com/cb'], 'redirect_uris -> redirectUris';
    is_deeply $body->{responseTypes}, ['OIDC_RESPONSE_TYPE_CODE'], 'response_types -> responseTypes';
    is_deeply $body->{grantTypes}, ['OIDC_GRANT_TYPE_AUTHORIZATION_CODE'], 'grant_types -> grantTypes';
    is $body->{appType}, 'OIDC_APP_TYPE_WEB', 'app_type -> appType';
    is $body->{authMethodType}, 'OIDC_AUTH_METHOD_TYPE_BASIC', 'auth_method -> authMethodType';
    is_deeply $body->{postLogoutRedirectUris}, ['https://app.example.com/logout'], 'post_logout_uris -> postLogoutRedirectUris';
    is_deeply $body->{additionalOrigins}, ['https://app2.example.com'], 'additional_origins -> additionalOrigins';
}

# Service users and machine keys.
{
    my $mgmt = Local::Recorder->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
    );

    $mgmt->create_service_user(user_name => 'ci-bot', name => 'CI Bot', description => 'CI pipeline user');
    $mgmt->list_service_users(limit => 10);
    $mgmt->get_service_user('su1');
    $mgmt->delete_service_user('su1');

    $mgmt->add_machine_key('su1', type => 'KEY_TYPE_JSON', expiration_date => '2030-01-01T00:00:00Z');
    $mgmt->list_machine_keys('su1', limit => 5);
    $mgmt->remove_machine_key('su1', 'key1');

    my $c = $mgmt->calls;

    is $c->[0][0], 'POST', 'create_service_user uses POST';
    is $c->[0][1], '/users/machine', 'create_service_user path';
    is $c->[0][2]{userName}, 'ci-bot', 'create_service_user userName';
    is $c->[0][2]{name}, 'CI Bot', 'create_service_user name';
    is $c->[0][2]{description}, 'CI pipeline user', 'create_service_user description';

    is $c->[1][1], '/users/_search', 'list_service_users path';
    is $c->[1][2]{query}{limit}, 10, 'list_service_users limit';
    is $c->[1][2]{queries}[0]{typeQuery}{type}, 'TYPE_MACHINE', 'list_service_users filters by machine type';

    is_deeply $c->[2], ['GET', '/users/su1', undef], 'get_service_user path';
    is_deeply $c->[3], ['DELETE', '/users/su1', undef], 'delete_service_user path';

    is $c->[4][1], '/users/su1/keys', 'add_machine_key path';
    is $c->[4][2]{type}, 'KEY_TYPE_JSON', 'add_machine_key type';
    is $c->[4][2]{expirationDate}, '2030-01-01T00:00:00Z', 'add_machine_key expiration_date -> expirationDate';

    is $c->[5][1], '/users/su1/keys/_search', 'list_machine_keys path';
    is $c->[5][2]{query}{limit}, 5, 'list_machine_keys limit';

    is_deeply $c->[6], ['DELETE', '/users/su1/keys/key1', undef], 'remove_machine_key path';

    throws_ok { $mgmt->create_service_user(name => 'Bot') } qr/user_name required/, 'create_service_user validates user_name';
    throws_ok { $mgmt->add_machine_key(undef) } qr/user_id required/, 'add_machine_key validates user_id';
    throws_ok { $mgmt->remove_machine_key('u1', undef) } qr/key_id required/, 'remove_machine_key validates key_id';
}

# Password management and user metadata.
{
    my $mgmt = Local::Recorder->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
    );

    $mgmt->set_password('u1', password => 's3cr3t!', change_required => JSON::MaybeXS::true);
    $mgmt->request_password_reset('u1');

    $mgmt->set_user_metadata('u1', 'department', 'engineering');
    $mgmt->get_user_metadata('u1', 'department');
    $mgmt->list_user_metadata('u1', limit => 20);

    my $c = $mgmt->calls;

    is $c->[0][1], '/users/u1/password', 'set_password path';
    is $c->[0][2]{password}, 's3cr3t!', 'set_password body has password';
    ok $c->[0][2]{changeRequired}, 'set_password change_required -> changeRequired';

    is_deeply $c->[1], ['POST', '/users/u1/_reset_password', {}], 'request_password_reset path';

    is $c->[2][1], '/users/u1/metadata/department', 'set_user_metadata path';
    use MIME::Base64 qw(decode_base64);
    is decode_base64($c->[2][2]{value}), 'engineering', 'set_user_metadata value is base64-encoded';

    is_deeply $c->[3], ['GET', '/users/u1/metadata/department', undef], 'get_user_metadata path';

    is $c->[4][1], '/users/u1/metadata/_search', 'list_user_metadata path';
    is $c->[4][2]{query}{limit}, 20, 'list_user_metadata limit';

    throws_ok { $mgmt->set_password(undef, password => 'x') } qr/user_id required/, 'set_password validates user_id';
    throws_ok { $mgmt->set_password('u1') } qr/password required/, 'set_password validates password';
    throws_ok { $mgmt->set_user_metadata('u1', undef, 'v') } qr/key required/, 'set_user_metadata validates key';
    throws_ok { $mgmt->set_user_metadata('u1', 'k', undef) } qr/value required/, 'set_user_metadata validates value';
}

# Organization operations.
{
    my $mgmt = Local::Recorder->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
    );

    $mgmt->create_org(name => 'Acme Corp');
    $mgmt->list_orgs(limit => 50, queries => [{ nameQuery => { name => 'Acme' } }]);
    $mgmt->update_org(name => 'Acme Inc');
    $mgmt->deactivate_org;

    my $c = $mgmt->calls;

    is $c->[0][0], 'POST', 'create_org uses POST';
    is $c->[0][1], '/orgs', 'create_org path';
    is $c->[0][2]{name}, 'Acme Corp', 'create_org name';

    is $c->[1][1], '/orgs/_search', 'list_orgs path';
    is $c->[1][2]{query}{limit}, 50, 'list_orgs limit';
    is scalar @{ $c->[1][2]{queries} }, 1, 'list_orgs queries forwarded';

    is $c->[2][0], 'PUT', 'update_org uses PUT';
    is $c->[2][1], '/orgs/me', 'update_org path';
    is $c->[2][2]{name}, 'Acme Inc', 'update_org name';

    is_deeply $c->[3], ['POST', '/orgs/me/_deactivate', {}], 'deactivate_org path';

    throws_ok { $mgmt->create_org } qr/name required/, 'create_org validates name';
    throws_ok { $mgmt->update_org } qr/name required/, 'update_org validates name';
}

# Identity provider operations.
{
    my $mgmt = Local::Recorder->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
    );

    $mgmt->create_oidc_idp(
        name          => 'Google',
        client_id     => 'gid',
        client_secret => 'gsecret',
        issuer        => 'https://accounts.google.com',
        scopes        => ['openid', 'email'],
        auto_register => 1,
    );
    $mgmt->list_idps(limit => 5);
    $mgmt->get_idp('idp1');
    $mgmt->update_idp('idp1', name => 'Google Updated');
    $mgmt->activate_idp('idp1');
    $mgmt->deactivate_idp('idp1');
    $mgmt->delete_idp('idp1');

    my $c = $mgmt->calls;

    is $c->[0][0], 'POST', 'create_oidc_idp uses POST';
    is $c->[0][1], '/idps/oidc', 'create_oidc_idp path';
    is $c->[0][2]{name}, 'Google', 'create_oidc_idp name';
    is $c->[0][2]{clientId}, 'gid', 'create_oidc_idp clientId';
    is $c->[0][2]{clientSecret}, 'gsecret', 'create_oidc_idp clientSecret';
    is $c->[0][2]{issuer}, 'https://accounts.google.com', 'create_oidc_idp issuer';
    is_deeply $c->[0][2]{scopes}, ['openid', 'email'], 'create_oidc_idp scopes';
    ok $c->[0][2]{autoRegister}, 'create_oidc_idp auto_register -> autoRegister';

    is $c->[1][1], '/idps/_search', 'list_idps path';
    is $c->[1][2]{query}{limit}, 5, 'list_idps limit';

    is_deeply $c->[2], ['GET', '/idps/idp1', undef], 'get_idp path';

    is $c->[3][0], 'PUT', 'update_idp uses PUT';
    is $c->[3][1], '/idps/idp1', 'update_idp path';
    is $c->[3][2]{name}, 'Google Updated', 'update_idp name';

    is_deeply $c->[4], ['POST', '/idps/idp1/_activate',   {}], 'activate_idp path';
    is_deeply $c->[5], ['POST', '/idps/idp1/_deactivate', {}], 'deactivate_idp path';
    is_deeply $c->[6], ['DELETE', '/idps/idp1', undef],        'delete_idp path';

    throws_ok { $mgmt->create_oidc_idp(client_id => 'x', client_secret => 'y', issuer => 'z') }
        qr/name required/, 'create_oidc_idp validates name';
    throws_ok { $mgmt->create_oidc_idp(name => 'n', client_secret => 'y', issuer => 'z') }
        qr/client_id required/, 'create_oidc_idp validates client_id';
    throws_ok { $mgmt->get_idp(undef) }    qr/idp_id required/, 'get_idp validates idp_id';
    throws_ok { $mgmt->delete_idp(undef) } qr/idp_id required/, 'delete_idp validates idp_id';
    throws_ok { $mgmt->update_idp('i1') }  qr/name required/,   'update_idp validates name';
}

# _request produces API exception objects with typed class.
{
    my $ua = Local::MgmtUA->new(
        queue => [ Local::Response->new(
            is_success      => 0,
            status_line     => '403 Forbidden',
            decoded_content => encode_json({ message => 'permission denied' }),
        ) ],
    );

    my $mgmt = WWW::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
        ua       => $ua,
    );

    eval { $mgmt->_get('/users/x') };
    my $err = $@;
    ok ref $err && $err->isa('WWW::Zitadel::Error::API'), 'API errors throw WWW::Zitadel::Error::API';
    like "$err", qr/403 Forbidden/, 'API error stringifies with status';
    like "$err", qr/permission denied/, 'API error stringifies with api message';
    is $err->http_status, '403 Forbidden', 'API error http_status attribute';
    is $err->api_message, 'permission denied', 'API error api_message attribute';
}

done_testing;
