use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use WebService::Postex;
use DateTime;
use Sub::Override;
use JSON::XS qw(encode_json decode_json);

my $postex = WebService::Postex->new(
    base_uri     => 'https://demo.example.com',
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

is($request->method, 'POST', 'Request is a POST');
is($request->uri, 'https://demo.example.com/rest/data/v1/generation/raw/123456789', '.. with the correct endpoint');
is($request->headers->header('Authorization'), 'Bearer verysecret', '.. with correct authorization header');
is($request->headers->header('Content-Type'), 'application/json', '.. and correct content-type');
is($request->headers->header('Accept'), 'application/json', '.. and correct accept header');
cmp_deeply(decode_json($request->content), \%payload, '.. with the correct content');

{

    my %payload = (
        file     => 't/data/test.gz',
        filename => 'testfile.gz',
        foo      => 'bar',
    );
    my $response = $postex->generation_file_upload(%payload);
    cmp_deeply(
        $response,
        {
            id        => ignore(),
            submitted => ignore(),
            status    => 'queued',
        },
        "Got a valid response from the server"
    );

    is($request->method, 'POST', 'Request is a POST');
    is($request->uri, 'https://demo.example.com/rest/data/v1/generation/upload/123456789', '.. with the correct endpoint');
    is($request->headers->header('Authorization'), 'Bearer verysecret', '.. with correct authorization header');
    like($request->headers->header('Content-Type'), qr#^multipart/form-data; boundary=\w+$#, '.. and correct content-type');
    is($request->headers->header('Accept'), 'application/json', '.. and correct accept header');
}


done_testing;
