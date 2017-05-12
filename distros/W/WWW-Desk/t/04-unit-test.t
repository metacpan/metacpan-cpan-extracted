#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';

use WWW::Desk::Auth::oAuth::SingleAccessToken;

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use URI;

plan tests => 2;

subtest "WWW::Desk::Auth::oAuth::SingleAccessToken object attribute require test" => sub {
    plan tests => 6;

    throws_ok { WWW::Desk::Auth::oAuth::SingleAccessToken->new() } qr/Attribute \(api_key\) is required/, "missing api_key argument";

    throws_ok {
        WWW::Desk::Auth::oAuth::SingleAccessToken->new(api_key => 'API KEY')
    }
    qr/Attribute \(desk_url\) is required/, "missing desk_url argument";

    throws_ok {
        WWW::Desk::Auth::oAuth::SingleAccessToken->new(
            api_key  => 'API KEY',
            desk_url => 'http://desk.com'
            )
    }
    qr/Attribute \(secret_key\) is required/, "missing token argument";

    throws_ok {
        WWW::Desk::Auth::oAuth::SingleAccessToken->new(
            api_key    => 'API KEY',
            desk_url   => 'http://desk.com',
            secret_key => 'SECRET KEY'
            )
    }
    qr/Attribute \(token\) is required/, "missing token argument";

    throws_ok {
        WWW::Desk::Auth::oAuth::SingleAccessToken->new(
            api_key    => 'API KEY',
            desk_url   => 'http://desk.com',
            secret_key => 'SECRET KEY',
            token      => 'ACCESS TOKEN'
            )
    }
    qr/Attribute \(token_secret\) is required/, "missing token_secret argument";

    lives_ok {
        WWW::Desk::Auth::oAuth::SingleAccessToken->new(
            desk_url     => 'https://test.desk.com',
            api_key      => 'API KEY',
            secret_key   => 'API SECRET',
            token        => 'TOKEN',
            token_secret => 'TOKEN SECRET'
        );
    }
    "object constructed";
};

subtest "WWW::Desk::Auth::oAuth::SingleAccessToken method test" => sub {
    plan tests => 5;

    my $desk = WWW::Desk::Auth::oAuth::SingleAccessToken->new(
        desk_url     => 'https://test.desk.com',
        api_key      => 'API KEY',
        secret_key   => 'API SECRET',
        token        => 'TOKEN',
        token_secret => 'TOKEN SECRET',
        debug        => 1
    );

    is($desk->debug,       1,    'Debug initilized');
    is($desk->api_version, 'v2', 'API Version');

    my $response = $desk->call('/customers/search', 'GET', {email => 'a@a.com'});
    is($response->{code},    401,            '401 error code');
    is($response->{message}, 'Unauthorized', 'User not authorized');
    is($response->{data},    undef,          'No data returned');
};

done_testing();

