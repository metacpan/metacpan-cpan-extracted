use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

plan skip_all => 'TEST_LETSENCRYPT=1' unless $ENV{TEST_LETSENCRYPT} or -e '.test-all';

done_testing();
