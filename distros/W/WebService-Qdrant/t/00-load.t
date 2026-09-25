use strict;
use warnings;
use Test::More;

use_ok('WebService::Qdrant');
use_ok('WebService::Qdrant::UA');
use_ok('WebService::Qdrant::Response');

subtest 'default transport belongs to Qdrant' => sub {
   my $client = WebService::Qdrant->new(
      base_url => 'http://qdrant.invalid:6333');
   my $transport = eval { $client->ua };
   is($@, '', 'constructing the transport does not throw');
   isa_ok($transport, 'WebService::Qdrant::UA');
};

done_testing;
