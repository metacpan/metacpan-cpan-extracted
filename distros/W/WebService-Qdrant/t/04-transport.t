use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use QdrantTest qw(client_for json_response);
use JSON::MaybeXS;

my $json = JSON::MaybeXS->new(utf8 => 1);
for my $method (qw(get put post delete)) {
   subtest "$method sends separate query and body" => sub {
      my ($client, $http) = client_for(json_response(200,
         {status => 'ok', result => {exists => JSON::MaybeXS::false()}}));
      my $transport = WebService::Qdrant::UA->new(
         base_url => 'http://qdrant.invalid:6333/', ua => $http);
      my $query = {wait => JSON::MaybeXS::false(), timeout => 10};
      my $data = {points => [{id => 0, payload => {text => 'café'},
         vector => [0, -0.1, 0.5]}]};
      my $before = $json->encode($data);
      my $response = $transport->$method(
         url => '/collections/notes', query => $query, data => $data);
      isa_ok($response, 'WebService::Qdrant::Response');
      is(scalar @{$http->requests}, 1, 'one HTTP request');
      my $request = $http->requests->[0];
      is($request->method, uc $method, 'correct HTTP verb');
      is($request->uri->path, '/collections/notes', 'trailing slash normalized');
      is($request->uri->authority, 'qdrant.invalid:6333', 'configured host');
      my %actual = $request->uri->query_form;
      is_deeply(\%actual, {wait => 'false', timeout => 10}, 'query encoded');
      is_deeply($json->decode($request->content), $data, 'JSON object and UTF-8');
      is($request->header('Content-Type'), 'application/json', 'content type');
      is($request->header('Accept'), 'application/json', 'accept JSON');
      is_deeply($data, $json->decode($before), 'body data unchanged');
      ok(JSON::MaybeXS::is_bool($query->{wait}), 'query boolean unchanged');
      ok(!$response->result->{exists}, 'false result retained');
   };
}

subtest 'absent body and empty object differ' => sub {
   my ($client, $http) = client_for(json_response(200, {result => 1}));
   $client->ua->get(url => '/collections');
   is($http->requests->[0]->content, '', 'GET without body');
   $client->ua->put(url => '/collections/notes', data => {});
   is($http->requests->[1]->content, '{}', 'empty object is sent');
};

subtest 'JSON boolean true in query' => sub {
   my ($client, $http) = client_for(json_response(200, {}));
   $client->ua->post(url => '/collections/notes/points/delete',
      query => {wait => JSON::MaybeXS::true()});
   is($http->requests->[0]->uri->query, 'wait=true', 'true encoded as text');
};

subtest 'bad request arguments fail before HTTP' => sub {
   my ($client, $http) = client_for(json_response(200, {}));
   for my $args ({type => 'PATCH', url => '/collections'},
      {type => 'GET', url => 'https://elsewhere.invalid/'}) {
      eval { $client->ua->request(%$args) };
      ok($@, 'invalid request throws');
   }
   is(scalar @{$http->requests}, 0, 'no HTTP request attempted');
};

done_testing;
