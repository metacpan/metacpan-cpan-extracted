use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use WebService::Qdrant;
use WebService::Qdrant::UA;
use LWP::UserAgent;

subtest 'localhost defaults reach HTTP client' => sub {
   my $client = WebService::Qdrant->new;
   is($client->base_url, 'http://localhost:6333', 'default service URL');
   is($client->timeout, 30, 'default HTTP timeout');
   ok(!defined $client->api_key, 'authentication is optional');
   my $transport = $client->ua;
   isa_ok($transport, 'WebService::Qdrant::UA');
   is($transport->base_url, $client->base_url, 'transport gets URL');
   is($transport->ua->timeout, 30, 'LWP gets default timeout');
   ok(!defined $transport->ua->default_header('api-key'),
      'no authentication header by default');
   is(refaddr($client->ua), refaddr($transport), 'transport is reused');
};

subtest 'explicit settings reach HTTP client' => sub {
   my $client = WebService::Qdrant->new(
      base_url => 'https://qdrant.invalid:6333',
      api_key => 'test-key-only', timeout => 12);
   is($client->base_url, 'https://qdrant.invalid:6333', 'custom URL');
   is($client->api_key, 'test-key-only', 'key stored');
   is($client->timeout, 12, 'custom timeout');
   is($client->ua->base_url, $client->base_url, 'transport gets custom URL');
   is($client->ua->ua->timeout, 12, 'LWP gets custom timeout');
   is($client->ua->ua->default_header('api-key'), 'test-key-only',
      'authentication header configured');
   my $other = WebService::Qdrant->new;
   ok(!defined $other->ua->ua->default_header('api-key'),
      'credentials do not leak between instances');
};

subtest 'injected transport keeps its configuration' => sub {
   my $http = LWP::UserAgent->new(timeout => 7);
   $http->default_header('api-key' => 'injected-test-key');
   my $transport = WebService::Qdrant::UA->new(
      base_url => 'http://custom.invalid:6333', ua => $http);
   my $client = WebService::Qdrant->new(ua => $transport);
   is(refaddr($client->ua), refaddr($transport), 'uses supplied transport');
   is(refaddr($client->ua->ua), refaddr($http), 'uses supplied HTTP client');
   is($http->timeout, 7, 'preserves injected timeout');
   is($http->default_header('api-key'), 'injected-test-key',
      'preserves injected authentication');
};

done_testing;
