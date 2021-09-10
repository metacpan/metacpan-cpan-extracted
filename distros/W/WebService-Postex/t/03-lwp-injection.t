use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use WebService::Postex;
use LWP::UserAgent;
use DateTime;
use Sub::Override;
use JSON::XS qw(encode_json decode_json);

my $ua = LWP::UserAgent->new(
    agent => "testsuite",
);

my $postex = WebService::Postex->new(
    base_uri     => 'https://demo.example.com/foo',
    generator_id => 123456789,
    secret       => 'verysecret',
    ua           => $ua,
);

is($postex->ua->agent, "testsuite",
    "Injecting custom LWP object yields correct agent");

my $headers = $postex->ua->default_headers;
is(
    $headers->header('authorization'),
    'Bearer verysecret',
    ".. and still sets the auth header"
);

is($headers->header('accept'), 'application/json', '.. and the accept header');


done_testing;
