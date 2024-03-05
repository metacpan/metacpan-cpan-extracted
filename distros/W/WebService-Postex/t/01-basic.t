use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use WebService::Postex;
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
  'data' => {
    'id' => '2376865936612268384',

    # status is enum([qw(queued indexing processing done error)])
    'status'    => 'queued',
    'submitted' => '2024-02-07T18:48:19.631Z'
  },
  'info' => {
    'apiVersion'  => 'v2.0.0',
    'description' => 'Postex Public API'
  },
  'metadata' => undef,
  'paths'    => {
    'documentation' => {
      'description' => 'The Postex public API documentation',
      'href'        =>
        'https://developers.postex.com/postex-public-api-documentation/',
      'type' => 'text/html'
    },
    'otherUpload' => {
      'description' =>
        'Submit fileupload to a generator by its ID using POST request.',
      'href' =>
        'https://api.nl.postex-accept.com/rest/v2/generators/1088304668653657870',
      'type' => 'multipart/form-data'
    },
    'self' => {
      'description' =>
        'Submit JSON or XML body to a generator by its ID using POST request.',
      'href' =>
        'https://api.nl.postex-accept.com/rest/v2/generators/1088304668653657870/raw',
      'type' => '*'
    },
    'sessionStatus' => {
      'description' =>
        'Retrieve the status of a generator session using a GET request',
      'href' =>
        'https://api.nl.postex-accept.com/rest/v2/generator-sessions/2376865936612268384',
      'type' => 'application/json'
    }
  }
};

my $override = Sub::Override->new(
  'LWP::UserAgent::send_request' => sub {
    my $self = shift;
    $request = shift;
    my $json = encode_json($data);
    $data->{data}{id}++;
    return HTTP::Response->new(200, 'OK', [], $json);
  },
);

my %payload  = (foo => 'bar');
my $response = $postex->generation_rest_upload(%payload);
cmp_deeply(
  $response,
  {
    data => {
        id => '2376865936612268384',
        status => 'queued',
        submitted => '2024-02-07T18:48:19.631Z',
    },
    info => ignore(),
    metadata => ignore(),
    paths => ignore(),
  },
  "Got a valid response from the server"
);

is($request->method, 'PUT', 'Request is a PUT');
is(
  $request->uri,
  'https://demo.example.com/rest/v2/generators/123456789/generate',
  '.. with the correct endpoint'
);

is(
  $request->headers->header('Authorization'),
  'Bearer verysecret',
  '.. with correct authorization header'
);
is($request->headers->header('Content-Type'),
  'application/json', '.. and correct content-type');
is($request->headers->header('Accept'),
  'application/json', '.. and correct accept header');
cmp_deeply(decode_json($request->content),
  \%payload, '.. with the correct content');

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
      data => {
        id        => '2376865936612268385',
        status    => 'queued',
        submitted => '2024-02-07T18:48:19.631Z',
      },
      info     => ignore(),
      metadata => ignore(),
      paths    => ignore(),
    },
    "Got a valid response from the server"
  );

  is($request->method, 'PUT', 'Request is a PUT');
  is(
    $request->uri,
    'https://demo.example.com/rest/v2/generators/123456789/generate',
    '.. with the correct endpoint'
  );
  is(
    $request->headers->header('Authorization'),
    'Bearer verysecret',
    '.. with correct authorization header'
  );
  like(
    $request->headers->header('Content-Type'),
    qr#^multipart/form-data; boundary=\w+$#,
    '.. and correct content-type'
  );
  is($request->headers->header('Accept'),
    'application/json', '.. and correct accept header');
}


done_testing;
