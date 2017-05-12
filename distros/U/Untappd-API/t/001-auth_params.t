use strict;
use warnings;
use Test::More;
use Untappd::API;

subtest 'default endpoint' => sub {
    my $api = Untappd::API->new(
        client_id     => 123,
        client_secret => 'abc',
    );;

    is $api->endpoint, 'http://api.untappd.com/v4', 'default endpoint defined';
    is $api->client_id, 123, 'client_id set properly';
    is $api->client_secret, 'abc', 'client_secret set properly';
    is $api->_auth_params, '&client_id=123&client_secret=abc', 'auth_params properly set';
};

subtest 'custom endpoint' => sub {
    my $api = Untappd::API->new(
        endpoint      => 'http://example.com',
        client_id     => 'def',
        client_secret => 456,
    );;

    is $api->endpoint, 'http://example.com', 'default endpoint defined';
    is $api->client_id, 'def', 'client_id set properly';
    is $api->client_secret, 456, 'client_secret set properly';
    is $api->_auth_params, '&client_id=def&client_secret=456', 'auth_params properly set';
};

done_testing;
