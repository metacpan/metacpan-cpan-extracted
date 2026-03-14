use strict;
use warnings;
use Test::More;
use Test::Exception;

use WWW::Zitadel;
use WWW::Zitadel::OIDC;
use WWW::Zitadel::Management;
use WWW::Zitadel::Error;

# WWW::Zitadel requires issuer
throws_ok { WWW::Zitadel->new } qr/required/, 'WWW::Zitadel needs issuer';
throws_ok { WWW::Zitadel->new(issuer => '') } qr/issuer must not be empty/, 'WWW::Zitadel rejects empty issuer';
{
    eval { WWW::Zitadel->new(issuer => '') };
    ok ref $@ && $@->isa('WWW::Zitadel::Error::Validation'), 'empty issuer throws Validation exception';
}

my $z = WWW::Zitadel->new(issuer => 'https://zitadel.example.com');
isa_ok $z, 'WWW::Zitadel';
is $z->issuer, 'https://zitadel.example.com', 'issuer set correctly';

# OIDC requires issuer
throws_ok { WWW::Zitadel::OIDC->new } qr/required/, 'OIDC needs issuer';
throws_ok { WWW::Zitadel::OIDC->new(issuer => '') } qr/issuer must not be empty/, 'OIDC rejects empty issuer';

my $oidc = WWW::Zitadel::OIDC->new(issuer => 'https://zitadel.example.com');
isa_ok $oidc, 'WWW::Zitadel::OIDC';
is $oidc->issuer, 'https://zitadel.example.com', 'OIDC issuer correct';
isa_ok $oidc->ua, 'LWP::UserAgent', 'OIDC has UA';

# Management requires base_url and token
throws_ok { WWW::Zitadel::Management->new } qr/required/, 'Management needs base_url+token';
throws_ok {
    WWW::Zitadel::Management->new(base_url => 'https://z.example.com')
} qr/required/, 'Management needs token';
throws_ok {
    WWW::Zitadel::Management->new(base_url => '', token => 'x')
} qr/base_url must not be empty/, 'Management rejects empty base_url';
{
    eval { WWW::Zitadel::Management->new(base_url => '', token => 'x') };
    ok ref $@ && $@->isa('WWW::Zitadel::Error::Validation'), 'empty base_url throws Validation exception';
}

my $mgmt = WWW::Zitadel::Management->new(
    base_url => 'https://zitadel.example.com',
    token    => 'test-pat-token',
);
isa_ok $mgmt, 'WWW::Zitadel::Management';
is $mgmt->base_url, 'https://zitadel.example.com', 'Management base_url';
is $mgmt->token, 'test-pat-token', 'Management token';

# Lazy OIDC from main object
my $z2 = WWW::Zitadel->new(
    issuer => 'https://z2.example.com',
    token  => 'my-pat',
);
isa_ok $z2->oidc, 'WWW::Zitadel::OIDC', 'lazy OIDC';
is $z2->oidc->issuer, 'https://z2.example.com', 'OIDC inherits issuer';

# Management requires token via main object
my $z3 = WWW::Zitadel->new(issuer => 'https://z3.example.com');
throws_ok { $z3->management } qr/requires a token/, 'management without token dies';

isa_ok $z2->management, 'WWW::Zitadel::Management', 'lazy Management';

# verify_token requires a token argument
throws_ok { $oidc->verify_token(undef) } qr/No token/, 'verify_token needs token';

# userinfo requires access_token
throws_ok { $oidc->userinfo(undef) } qr/No access token/, 'userinfo needs token';

# Management methods require IDs
throws_ok { $mgmt->get_user(undef) } qr/user_id required/, 'get_user needs id';
throws_ok { $mgmt->get_project(undef) } qr/project_id required/, 'get_project needs id';
throws_ok { $mgmt->get_app(undef, 'x') } qr/project_id required/, 'get_app needs project_id';
throws_ok { $mgmt->get_app('p', undef) } qr/app_id required/, 'get_app needs app_id';

# Exception classes stringify to their message
{
    my $err = WWW::Zitadel::Error::API->new(
        message     => 'API error: 404 Not Found - user not found',
        http_status => '404 Not Found',
        api_message => 'user not found',
    );
    is "$err", 'API error: 404 Not Found - user not found', 'API error stringifies to message';
    is $err->http_status, '404 Not Found', 'API error has http_status';
    is $err->api_message, 'user not found', 'API error has api_message';
    ok $err->isa('WWW::Zitadel::Error'), 'API error isa WWW::Zitadel::Error';

    my $net = WWW::Zitadel::Error::Network->new(message => 'Discovery failed: 503 Service Unavailable');
    is "$net", 'Discovery failed: 503 Service Unavailable', 'Network error stringifies';
    ok $net->isa('WWW::Zitadel::Error'), 'Network error isa WWW::Zitadel::Error';

    my $val = WWW::Zitadel::Error::Validation->new(message => 'user_id required');
    is "$val", 'user_id required', 'Validation error stringifies';
}

done_testing;
