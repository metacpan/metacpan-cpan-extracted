use strict;
use warnings;
use Test::More;
use LWP::UserAgent;
use JSON::MaybeXS;
use WebService::Qdrant;

# Only the availability probe may skip. Once Qdrant is identified, errors fail.
my $url = $ENV{QDRANT_TEST_URL} // 'http://localhost:6333';
$url =~ s{/+\z}{};
my $probe = LWP::UserAgent->new(timeout => 2);
$probe->default_header('api-key' => $ENV{QDRANT_TEST_API_KEY})
   if defined $ENV{QDRANT_TEST_API_KEY};
my $http = $probe->get("$url/");
if (($http->header('Client-Warning') // '') eq 'Internal response') {
   plan skip_all => "Qdrant unavailable at $url: " . $http->status_line;
}
my $info = eval { JSON::MaybeXS->new->decode($http->decoded_content) };
if (!$http->is_success || ref($info) ne 'HASH'
   || ($info->{title} // '') !~ /\Aqdrant(?: - vector search engine)?\z/) {
   fail('availability probe identifies a Qdrant server');
   diag('Expected Qdrant at ' . $url . '; got ' . $http->status_line);
   done_testing;
   exit;
}

my $client = WebService::Qdrant->new(
   base_url => $url, timeout => 10,
   api_key => $ENV{QDRANT_TEST_API_KEY},
);
my @letters = ('a' .. 'z');
my $name = 'webservice_qdrant_test_' . join '', map { $letters[rand @letters] } 1 .. 24;
my $cleanup_needed = 0;
my $true = JSON::MaybeXS::true();

# A guard also handles die/exit outside the main eval. SIGKILL cannot be cleaned up.
sub cleanup {
   return unless $cleanup_needed;
   my $response = $client->delete_collection(collection_name => $name);
   die 'Collection cleanup failed: ' . $response->raw_content
      unless $response->is_success && !$response->decode_error && $response->result;
   $cleanup_needed = 0;
   return;
}
END {
   if ($cleanup_needed) {
      eval { cleanup() };
      warn "Could not clean up test collection $name: $@" if $@;
   }
}

sub checked {
   my ($method, %args) = @_;
   my $response = $client->$method(collection_name => $name, %args);
   isa_ok($response, 'WebService::Qdrant::Response', $method);
   ok($response->is_success, "$method HTTP success");
   ok(!defined $response->decode_error, "$method valid JSON");
   die "$method failed: " . $response->raw_content
      unless $response->is_success && !defined $response->decode_error;
   return $response;
}

note("Live Qdrant $info->{version} at $url; temporary collection $name");
my $completed = eval {
   my $exists = checked('collection_exists');
   die 'Random collection name already exists; leaving it untouched'
      if $exists->result->{exists};
   ok(!$exists->result->{exists}, 'temporary name is unused');

   # Mark before sending: a lost create response may still leave a collection.
   $cleanup_needed = 1;
   my $created = checked('create_collection',
      vectors => {size => 3, distance => 'Cosine'});
   ok($created->result, 'collection created');
   ok(checked('collection_exists')->result->{exists}, 'collection now exists');
   my $config = checked('get_collection')->result->{config}{params}{vectors};
   is($config->{size}, 3, 'configured vector dimensions');
   is($config->{distance}, 'Cosine', 'configured distance');

   my $stored = checked('upsert', wait => $true, points => [
      {id => 1, vector => [1, 0, 0], payload => {text => 'red apple', group => 'fruit'}},
      {id => 2, vector => [0, 1, 0], payload => {text => 'blue sky', group => 'sky'}},
      {id => 3, vector => [0, 0, 1], payload => {text => 'green pear', group => 'fruit'}},
   ]);
   is($stored->result->{status}, 'completed', 'upsert waited for completion');
   my $hits = checked('query_points', query => [1, 0, 0],
      limit => 3, with_payload => $true)->result->{points};
   is(scalar @$hits, 3, 'all uploaded points are searchable');
   is($hits->[0]{id}, 1, 'exact vector is nearest');
   cmp_ok(abs($hits->[0]{score} - 1), '<', 0.00001, 'expected cosine score');
   is_deeply($hits->[0]{payload}, {text => 'red apple', group => 'fruit'},
      'payload round trips');

   is(checked('delete_points', points => [1], wait => $true)->result->{status},
      'completed', 'ID deletion completed');
   my $remaining = checked('query_points', query => [1, 0, 0], limit => 3)->result->{points};
   is_deeply([sort {$a <=> $b} map {$_->{id}} @$remaining], [2, 3],
      'only selected ID was removed');

   checked('delete_points', wait => $true,
      filter => {must => [{key => 'group', match => {value => 'fruit'}}]});
   $remaining = checked('query_points', query => [0, 1, 0], limit => 3)->result->{points};
   is_deeply([map {$_->{id}} @$remaining], [2], 'filter deletes only matching points');
   1;
};
if (!$completed) {
   fail('live collection lifecycle completed');
   diag($@);
}
my $cleaned = eval { cleanup(); 1 };
ok($cleaned, 'temporary collection cleanup succeeded');
diag($@) unless $cleaned;
if ($cleaned && $completed) {
   my $verified = eval {
      ok(!checked('collection_exists')->result->{exists}, 'collection is gone');
      1;
   };
   if (!$verified) {
      fail('cleanup verification completed');
      diag($@);
   }
}
done_testing;
