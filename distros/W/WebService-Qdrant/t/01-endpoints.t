use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use QdrantTest qw(client_for json_response);
use JSON::MaybeXS;

my $json = JSON::MaybeXS->new(utf8 => 1);
my $true = JSON::MaybeXS::true();
my $false = JSON::MaybeXS::false();
my $points = [{id => 0, vector => [0, 0.25, -0.5],
   payload => {text => 'Ruth’s café', source => 'notes.md'}}];
my $filter = {must => [{key => 'source', match => {value => 'notes.md'}}]};
my $operation = {operation_id => 0, status => 'completed'};

# method, HTTP verb, suffix, body, URL parameters, result
my @cases = (
   ['create_collection', 'PUT', '',
      {vectors => {size => 3, distance => 'Cosine'}}, {timeout => 10}, $true],
   ['delete_collection', 'DELETE', '', {}, {timeout => 10}, $true],
   ['get_collection', 'GET', '', {}, {},
      {status => 'green', points_count => 0,
       config => {params => {vectors => {size => 3, distance => 'Cosine'}}}}],
   ['collection_exists', 'GET', '/exists', {}, {}, {exists => $true}],
   ['collection_exists', 'GET', '/exists', {}, {}, {exists => $false}],
   ['upsert', 'PUT', '/points', {points => $points},
      {wait => 'true', ordering => 'strong'}, $operation],
   ['upsert', 'PUT', '/points',
      {batch => {ids => [0], vectors => [[0, 0.25, -0.5]],
         payloads => [{source => 'notes.md'}]}}, {wait => 'false'}, $operation],
   ['query_points', 'POST', '/points/query',
      {query => [0, 0.25, -0.5], filter => $filter, limit => 5,
       with_payload => $true, with_vector => $false}, {timeout => 10},
      {points => [{id => 0, score => 0.99, payload => $points->[0]{payload}}]}],
   ['query_points', 'POST', '/points/query',
      {query => [0, 0.25, -0.5], limit => 5}, {}, {points => []}],
   ['delete_points', 'POST', '/points/delete', {points => [0, 42]},
      {wait => 'true'}, $operation],
   ['delete_points', 'POST', '/points/delete', {filter => $filter},
      {wait => 'false'}, $operation],
);

for my $case (@cases) {
   my ($method, $verb, $suffix, $body, $query, $result) = @$case;
   subtest "$method $verb $suffix " . $json->encode($result) => sub {
      my ($client, $http) = client_for(json_response(200,
         {status => 'ok', time => 0.001, result => $result}));
      my %args = (collection_name => 'book-notes', %$body, %$query);
      # Public boolean options are actual JSON booleans; URL values are text.
      $args{wait} = $query->{wait} eq 'true' ? $true : $false
         if exists $query->{wait};
      my $before = $json->decode($json->encode(\%args));
      my $response = eval { $client->$method(%args) };
      is($@, '', 'API call does not throw');
      isa_ok($response, 'WebService::Qdrant::Response');
      is_deeply(\%args, $before, 'caller data is unchanged');
      is(scalar @{$http->requests}, 1, 'one HTTP request');
      if (my $request = $http->requests->[0]) {
         is($request->method, $verb, 'correct HTTP method');
         is($request->uri->scheme, 'http', 'configured scheme');
         is($request->uri->authority, 'qdrant.invalid:6333', 'configured host');
         is($request->uri->path, '/collections/book-notes' . $suffix,
            'correct endpoint');
         my %actual_query = $request->uri->query_form;
         is_deeply(\%actual_query, $query, 'options belong in URL query');
         if (keys %$body) {
            like($request->header('Content-Type') || '', qr{application/json},
               'JSON content type');
            my $decoded = eval { $json->decode($request->content) };
            is($@, '', 'body is valid JSON');
            is_deeply($decoded, $body, 'exact JSON object, without URL options');
         } else {
            ok(!length($request->content || ''), 'no unnecessary request body');
         }
      }
      if ($response && $response->can('result')) {
         is_deeply($response->result, $result, 'result survives decoding');
      } else {
         fail('response exposes result');
      }
   };
}

subtest 'collection names stay within one path segment' => sub {
   my ($client, $http) = client_for(json_response(200, {result => {}}));
   $client->get_collection(collection_name => 'notes/other?x=1#part');
   is($http->requests->[0]->uri->as_string,
      'http://qdrant.invalid:6333/collections/notes%2Fother%3Fx%3D1%23part',
      'reserved characters escaped');
};

subtest 'all wrappers require a collection name before HTTP' => sub {
   my ($client, $http) = client_for(json_response(200, {}));
   for my $method (qw(collection_exists create_collection delete_collection
      delete_points get_collection query_points upsert)) {
      for my $name (undef, '', []) {
         eval { $client->$method(collection_name => $name) };
         like($@, qr/collection_name/, "$method rejects invalid name");
      }
   }
   is(scalar @{$http->requests}, 0, 'no requests sent');
};

subtest 'query may omit a vector and accepts consistency' => sub {
   my ($client, $http) = client_for(json_response(200, {result => {points => []}}));
   $client->query_points(collection_name => 'notes', consistency => 'majority');
   is($http->requests->[0]->uri->query, 'consistency=majority',
      'consistency is a URL parameter');
   is($http->requests->[0]->content, '{}', 'empty query is a JSON object');
};

done_testing;
