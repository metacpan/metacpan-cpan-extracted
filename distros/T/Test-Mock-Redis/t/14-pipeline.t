#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use Test::Deep;
use Test::Fatal 'exception';
use Test::Deep::UnorderedPairs;
use Test::Mock::Redis ();

use lib 't/tlib';

ok(my $r = Test::Mock::Redis->new, 'pretended to connect to our test redis-server');
my @redi = ($r);

my ( $guard, $srv );
if( $ENV{RELEASE_TESTING} ){
    use_ok("Redis");
    use_ok("Test::SpawnRedisServer");
    ($guard, $srv) = redis();
    ok(my $r = Redis->new(server => $srv), 'connected to our test redis-server');
    $r->flushall;
    unshift @redi, $r
}

foreach my $redis (@redi)
{
    diag("testing $redis") if $ENV{RELEASE_TESTING};

    ok($redis->ping, 'ping');


    is(
        $redis->hmset(
            'pipeline_key_1', qw(a 1 b 2),
            sub { cmp_deeply(\@_, [ 'OK', undef ], 'hmset callback') },
        ),
        '1',
        'hmset command sent',
    );

    is(
        $redis->set(
            'pipeline_key_2', 'ohhai',
            sub { cmp_deeply(\@_, [ 'OK', undef ], 'set callback') },
        ),
        '1',
        'set command sent',
    );

    is(
        $redis->keys(
            'pipeline_key_*',
            sub { cmp_deeply(\@_, [ bag(qw(pipeline_key_1 pipeline_key_2)), undef ], 'keys callback') },
        ),
        '1',
        'keys operation sent',
    );

    cmp_deeply(
        [
            $redis->hgetall(
                'pipeline_key_1',
                sub { cmp_deeply(\@_, [ tuples(a => 1, b => 2), undef ], 'hgetall callback') },
            ),
        ],
        [ '1' ],
        'hgetall operation sent (wantarray=1)',
    );

    is(
        $redis->hset(
            'pipeline_key_2', 'bar', '9',
            # weird, when pipelining, the real redis doesn't always include the command name?
            sub { cmp_deeply(\@_, [ undef, re(qr/^(\[hset\] )?WRONGTYPE Operation against a key holding the wrong kind of value/) ], 'hset callback') },
        ),
        '1',
        'hset operation sent',
    );

    # flush all outstanding commands and test their callbacks
    $redis->wait_all_responses;


    TODO: {
        # this may be officially supported eventually -- see
        # https://github.com/melo/perl-redis/issues/17

        local $TODO = 'Redis.pm docs recommend avoiding transactions + pipelining for now';

        is(
            exception {
                $redis->multi;
                is($redis->set('pipeline_key_2', 'ohhai'), 'QUEUED', 'set command queued inside a transaction');
                is(
                    $redis->exec(sub {
                        cmp_deeply(
                            \@_,
                            [
                                [
                                    [ 'OK', undef ],    # result, error from 'set' call
                                ],
                                undef,
                            ],
                            'callback sent arrayref of result/error tuples from the transaction',
                        )
                    }),
                    '1',
                    'exec command sent',
                );
                $redis->wait_all_responses;
            },
            undef,
            'exec in a pipeline is supported',
        );
    }
}


done_testing;
