use strict;
use warnings;

use Test::Most;
use Test::RedisDB;

use Tie::Hash::RedisDB;

my %test_hash;
my $test_server = Test::RedisDB->new;
SKIP: {
    skip 'Requires local Test::RedisDB for testing', 2
      unless $test_server;

    subtest 'simple tie' => sub {
        lives_ok {
            tie(
                %test_hash,
                'Tie::Hash::RedisDB',
                'simple',
                {
                    redis_uri => $test_server->url,
                    namespace => 'TESTTHRDB',
                    expiry    => 61
                });
        }
        'Hash tied';
    };

    subtest 'in and out' => sub {
        my $nonsense = {
            string  => 'a string',
            undef   => undef,
            integer => 128,
            float   => 3.1415926,
            unicode => '‽',
            object  => {
                unicode => '‽',
            },
            array => ['💩', '‽'],
        };
        %test_hash = %$nonsense;

        eq_or_diff({%test_hash}, $nonsense, 'Multivalue in and out works');
        is($test_hash{missing}, undef, 'Missing values return undef');
    };
};    # Test server SKIP block

done_testing;
