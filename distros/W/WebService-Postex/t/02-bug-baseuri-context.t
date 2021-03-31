use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use WebService::Postex;
use DateTime;
use Sub::Override;
use JSON::XS qw(encode_json decode_json);

my $postex = WebService::Postex->new(
    base_uri     => 'https://demo.example.com/foo',
    generator_id => 123456789,
    secret       => 'verysecret',
);

isa_ok($postex, 'WebService::Postex');

my $request;

my $data = {
    id        => 9876543210,
    submitted => DateTime->now->iso8601,
    status    => 'queued',
    # status is enum([qw(queued indexing processing done error)])
};

my $override = Sub::Override->new(
    'LWP::UserAgent::send_request' => sub {
        my $self = shift;
        $request = shift;
        my $json = encode_json($data);
        $data->{id}++;
        return HTTP::Response->new(200, 'OK', [], $json);
    },
);

my %payload = (foo => 'bar');
my $response = $postex->generation_rest_upload(%payload);
cmp_deeply(
    $response,
    {
        id        => ignore(),
        submitted => ignore(),
        status    => 'queued',
    },
    "Got a valid response from the server"
);

is($request->uri, 'https://demo.example.com/foo/rest/data/v1/generation/raw/123456789', '.. with the correct endpoint');

done_testing;
