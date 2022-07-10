use Test::Lib;
use Test::WebService::ValidSign;

use HTTP::Response;
use LWP::UserAgent;

{
    my $client = WebService::ValidSign->new(
        secret   => 'Foo',
    );

    my $call_count = 0;

    my $auth = $client->auth;

    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
            $call_count++;
            return HTTP::Response->new(
                200, 'OK', [], '{ "value" : "a very secret token" }'
            );
        },
    );

    my $token = $auth->token();
    is($token, "a very secret token", "Got a token from the API");
    is($client->token, $token, "... client->token also works");
    is($call_count, 1, "... and the token is cached");

    is(
        $auth->get_endpoint("foo"),
        'https://try.validsign.nl/api/foo',
        "Got the correct endpoint"
    );

    {
        # Test to see if multiple empty path sections are stripped off
        my $client = WebService::ValidSign->new(
            secret   => 'Foo',
            endpoint => 'https://foo.bar.nl/bar//',
        );
        is(
            $client->auth->get_endpoint("foo"),
            'https://foo.bar.nl/bar/foo',
            "Got the correct endpoint"
        );
    }
}

SKIP: {

    use List::Util qw(none);

    if ($ENV{NO_NETWORK_TESTING} || none { $_ =~ /^VALIDSIGN_/ } keys %ENV) {
        my $reason = q{
These tests require internet connectivity and some environment variables:
NO_NETWORK_TESTING set to 0
VALIDSIGN_API_ENDPOINT
VALIDSIGN_API_KEY
};
        skip $reason, 1;
    }

    my $client = WebService::ValidSign->new(
        endpoint => $ENV{VALIDSIGN_API_ENDPOINT},
        secret   => $ENV{VALIDSIGN_API_KEY},
    );

    isnt($client->auth->token, undef,
        "Got a token from the endpoint " . $client->endpoint);
    is($client->auth->token, $client->auth->token,
        "Multiple token calls yield the same token");

    note "And the token is: " .  $client->auth->token;
}

done_testing;
