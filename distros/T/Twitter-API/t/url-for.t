use strict;
use warnings;
use Test::More;

use Twitter::API;

my $client = Twitter::API->new_with_traits(
    traits          => 'AppAuth',
    consumer_key    => 'key',
    consumer_secret => 'secret',
);

is(
    $client->api_url_for('some/endpoint'),
    'https://api.twitter.com/1.1/some/endpoint.json',
    'api url'
);

is(
    $client->upload_url_for('some/endpoint'),
    'https://upload.twitter.com/1.1/some/endpoint.json',
    'upload url'
);

is(
    $client->oauth_url_for('some/endpoint'),
    'https://api.twitter.com/oauth/some/endpoint',
    'oauth url'
);

is(
    $client->oauth2_url_for('some/endpoint'),
    'https://api.twitter.com/oauth2/some/endpoint',
    'oauth2 url'
);

{
    my $url = 'http://my.custom.url/endpoint';
    is($client->api_url_for($url), $url, 'custom url');
}

done_testing;
