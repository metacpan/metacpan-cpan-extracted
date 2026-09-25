use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use QdrantTest qw(client_for json_response);
use HTTP::Response;

# Proposed response contract: result/status/time preserve Qdrant's envelope;
# is_success/http_code/raw_content also make non-JSON HTTP errors inspectable.
for my $code (200, 400, 401, 404, 409, 422, 429, 500, 503) {
   subtest "HTTP $code returns a response" => sub {
      my $status = $code == 200 ? 'ok' : {error => 'Qdrant rejected request'};
      my $result = $code == 200 ? {points_count => 0} : undef;
      my $wire = json_response($code,
         {status => $status, result => $result, time => 0.002});
      my ($client) = client_for($wire);
      my $response = eval { $client->ua->get(url => '/collections/notes') };
      is($@, '', 'HTTP response is not a catastrophic failure');
      isa_ok($response, 'WebService::Qdrant::Response');
      return if !defined $response;
      for my $field (qw(result status time http_code is_success raw_content)) {
         can_ok($response, $field);
      }
      is_deeply($response->result, $result, 'result retained')
         if $response->can('result');
      is_deeply($response->status, $status, 'status retained')
         if $response->can('status');
      is($response->time, 0.002, 'server timing retained')
         if $response->can('time');
      is($response->http_code, $code, 'HTTP code retained')
         if $response->can('http_code');
      is(!!$response->is_success, $code == 200, 'success follows HTTP outcome')
         if $response->can('is_success');
      is($response->raw_content, $wire->content, 'original body retained')
         if $response->can('raw_content');
   };
}

for my $body ('<html>Bad gateway</html>', '', '{broken json') {
   subtest "non-JSON HTTP error: $body" => sub {
      my ($client) = client_for(HTTP::Response->new(502, 'Bad Gateway',
         ['Content-Type' => 'text/plain'], $body));
      my $response = eval { $client->ua->get(url => '/collections/notes') };
      is($@, '', 'unparseable server error still returns normally');
      isa_ok($response, 'WebService::Qdrant::Response');
      return if !defined $response;
      can_ok($response, qw(http_code raw_content is_success));
      is($response->raw_content, $body, 'error body available to caller')
         if $response->can('raw_content');
      is($response->http_code, 502, 'gateway status retained')
         if $response->can('http_code');
      ok(!$response->is_success, 'error is not successful')
         if $response->can('is_success');
   };
}

# LWP usually represents connection failure as a synthetic HTTP response.
# A real server 500 above must not be mistaken for this internal response.
my $connection_failure = HTTP::Response->new(500, 'Cannot connect',
   ['Client-Warning' => 'Internal response', 'Content-Type' => 'text/plain'],
   'Connection refused');
for my $failure ($connection_failure, "Connection refused\n") {
   subtest 'transport failure throws' => sub {
      my ($client, $http) = client_for($failure);
      my $response = eval { $client->ua->get(url => '/collections/notes') };
      my $error = $@;
      is(scalar @{$http->requests}, 1, 'failure came from attempted HTTP request');
      ok(!defined $response, 'no fabricated API response');
      like($error, qr/Connection refused/i, 'connection failure reaches caller');
   };
}

subtest 'complete JSON and decoding diagnostics' => sub {
   for my $body ('null', '[]', 'false', '{"result":false,"extra":42}') {
      my $response = WebService::Qdrant::Response->new(
         http_code => 200, raw_content => $body);
      ok(!defined $response->decode_error, 'valid JSON has no decoding error');
      is_deeply($response->json_response,
         JSON::MaybeXS->new->decode($body), 'entire JSON value retained');
      ok($response->is_success, 'HTTP success independent of result shape');
   }
   for my $body ('', '<html>Oops</html>', '{bad') {
      my $response = WebService::Qdrant::Response->new(
         http_code => 200, raw_content => $body);
      ok($response->decode_error, 'invalid JSON has diagnostic');
      ok(!defined $response->result, 'invalid body has no result');
      is($response->raw_content, $body, 'body preserved');
   }
   for my $code (199, 200, 204, 299, 300) {
      my $response = WebService::Qdrant::Response->new(
         http_code => $code, raw_content => '{}');
      is(!!$response->is_success, $code >= 200 && $code < 300,
         "HTTP success boundary $code");
   }
};

subtest 'usage information is preserved when present' => sub {
   my $usage = {hardware => {cpu => 1, vector_io_read => 0},
      inference => {models => {}}};
   my ($client) = client_for(json_response(200,
      {status => 'ok', result => {}, usage => $usage}));
   my $response = $client->ua->get(url => '/collections/notes');
   is_deeply($response->usage, $usage, 'nested usage data is preserved');
   for my $body ('{}', 'null', '[]', '{broken') {
      my $without_usage = WebService::Qdrant::Response->new(
         http_code => 200, raw_content => $body);
      is($without_usage->usage, undef, 'unavailable usage returns undef');
   }
};

done_testing;
