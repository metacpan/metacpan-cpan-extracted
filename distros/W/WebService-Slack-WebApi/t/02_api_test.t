use strict;
use warnings;
use utf8;
use feature qw/state/;

use Test::More;
use Test::Exception;
use lib '.';
use t::Util qw/ slack set_mock_response /;

subtest 'test' => sub {
    set_mock_response {
        ok => 1,
        args => {
            hoge => 'fuga',
            piyo => '!!',
        },
    };

    my $result = slack->api->test(hoge => 'fuga', piyo => '!!');
    isa_ok $result, 'HASH';
    is_deeply $result, {
        ok => 1,
        args => {
            hoge => 'fuga',
            piyo => '!!',
        },
    };
};

subtest 'response failure' => sub {
    set_mock_response +{}, 0;
    throws_ok {
        slack->api->test(hoge => 'fuga', piyo => '!!');
    } 'WebService::Slack::WebApi::Exception::FailureResponse';
};

done_testing;

