#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';

use WWW::Desk::Auth::oAuth;

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use URI;

plan tests => 2;

subtest "WWW::Desk::Browser object attribute require test" => sub {
    plan tests => 6;

    throws_ok { WWW::Desk::Auth::oAuth->new() } qr/Attribute \(api_key\) is required/, "missing api_key argument";

    throws_ok {
        WWW::Desk::Auth::oAuth->new(api_key => 'API KEY')
    }
    qr/Attribute \(callback_url\) is required/, "missing callback_url argument";

    throws_ok {
        WWW::Desk::Auth::oAuth->new(
            api_key      => 'API KEY',
            callback_url => 'http://google.com'
            )
    }
    qr/Attribute \(callback_url\) does not pass the type constraint/, "callback_url should be URI object";

    throws_ok {
        WWW::Desk::Auth::oAuth->new(
            api_key      => 'API KEY',
            callback_url => URI->new('http://google.com'))
    }
    qr/Attribute \(desk_url\) is required/, "missing desk_url argument";

    throws_ok {
        WWW::Desk::Auth::oAuth->new(
            api_key      => 'API KEY',
            callback_url => URI->new('http://google.com'),
            desk_url     => 'http://desk.com'
            )
    }
    qr/Attribute \(secret_key\) is required/, "missing secret_key argument";

    lives_ok {
        WWW::Desk::Auth::oAuth->new(
            desk_url     => 'https://test.desk.com',
            callback_url => URI->new('http://google.com'),
            api_key      => 'API KEY',
            secret_key   => 'API SECRET'
        );
    }
    "object constructed";
};

subtest "WWW::Desk::Browser method test" => sub {
    plan tests => 9;

    my $desk = WWW::Desk::Auth::oAuth->new(
        desk_url     => 'https://test.desk.com',
        callback_url => URI->new('http://google.com'),
        api_key      => 'API KEY',
        secret_key   => 'API SECRET',
        debug        => 1
    );

    can_ok($desk, ('authorization_url', 'request_access_token'));
    isa_ok($desk->auth_client, 'Net::OAuth::Client');
    is($desk->debug,       1,    'Debug initilized');
    is($desk->api_version, 'v2', 'API Version');

    throws_ok { $desk->authorization_url } qr/Unable to get/, "Unable to get authorization_url";

    is($desk->build_api_url('/wow'), 'https://test.desk.com/api/v2/wow', 'Prepare URL works');

    is($desk->build_api_url('wow'), 'https://test.desk.com/api/v2/wow', 'Prepare URL ');

    my %data = $desk->_session(1, 2);
    is(ref \%data, 'HASH', 'internal session');

    throws_ok { $desk->request_access_token('sdd', 'dfd') } qr/Missing required parameter/, "Unable to get 'token_secret'";

};

done_testing();

