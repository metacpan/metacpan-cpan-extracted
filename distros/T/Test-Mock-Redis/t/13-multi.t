#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use Test::Deep;
use Test::Fatal;
use Test::Mock::Redis;

use lib 't/tlib';

=pod
x   MULTI
x   EXEC
x   DISCARD
=cut

# There is a known issue in the real Redis client that screws up the
# interpretation of all results from the client after an error in the middle of
# a multi -- https://github.com/melo/perl-redis/issues/42
# Because of this, this one test file uses a subref for its redis object,
# rather than the object itself, so it can get a new object at the right time
# so we can continue tests...

my $r = sub { Test::Mock::Redis->new };
ok($r->(), 'pretended to connect to our test redis-server');
my @redi = ($r);

my ( $guard, $srv );
if( $ENV{RELEASE_TESTING} ){
    use_ok("Redis");
    use_ok("Test::SpawnRedisServer");
    ($guard, $srv) = redis();

    my $r = sub { Redis->new(server => $srv) };
    my $redis = $r->();
    ok($redis, 'connected to our test redis-server');
    $redis->flushall;
    unshift @redi, $r
}

foreach my $o (@redi)
{
    my $redis = $o->();

    diag("testing $redis") if $ENV{RELEASE_TESTING};

    ok($redis->ping, 'ping');

    like(
        exception { $redis->exec },
        qr/^\[exec\] ERR EXEC without MULTI/,
        'cannot call EXEC before MULTI',
    );

    like(
        exception { $redis->discard },
        qr/^\[discard\] ERR DISCARD without MULTI/,
        'cannot call DISCARD before MULTI',
    );

    like(
        exception { $redis->multi; $redis->multi },
        qr/^\[multi\] ERR MULTI calls can not be nested/,
        'cannot call MULTI again until EXEC or DISCARD is called',
    );

    is($redis->discard, 'OK', 'multi state has been reset');


    # discarded transactions

    is($redis->multi, 'OK', 'multi transaction started');
    is($redis->hmset('transaction_key_1', qw(a 1 b 2)), 'QUEUED', 'hmset operation recorded');

    cmp_deeply(
        $redis->discard,
        'OK',
        'transaction discarded',
    );

    cmp_deeply(
        { $redis->hgetall('transaction_key_1') },
        { },
        'data was not altered',
    );


    # successful transactions

    is($redis->watch('transaction_key_3'), 'OK', 'watch command');

    is($redis->multi, 'OK', 'multi transaction started');
    is($redis->hmset('transaction_key_3', qw(a 1 b 2)), 'QUEUED', 'hmset operation recorded');
    cmp_deeply([ $redis->keys('transaction_key_*') ], [ 'QUEUED' ], 'keys operation recorded');
    is($redis->set('transaction_key_4', 'ohhai'), 'QUEUED', 'set operation recorded');
    cmp_deeply([ $redis->keys('transaction_key_*') ], [ 'QUEUED' ], 'keys operation recorded');

    cmp_deeply(
        [ $redis->exec ],
        [
            'OK',
            [ 'transaction_key_3' ],    # transaction_key_4 hasn't been set yet
            'OK',
            bag(qw(transaction_key_3 transaction_key_4)),
        ],
        'transaction finished, returning the results of all queries',
    );

    is($redis->unwatch(), 'OK', 'unwatch command');

    cmp_deeply(
        { $redis->hgetall('transaction_key_3') },
        {
            a => '1',
            b => '2',
        },
        'hash data successfully recorded',
    );

    # an error in replaying a transaction should not abort subsequent commands
    # note: this mirrors behaviour in version 2.6.5+

    is($redis->multi, 'OK', 'multi transaction started');
    is($redis->set('transaction_key_1', 'foo'), 'QUEUED', 'set operation recorded');
    is($redis->hset('transaction_key_1', 'bar', '9'), 'QUEUED', 'hset operation recorded');
    is($redis->hset('transaction_key_3', 'a', '9'), 'QUEUED', 'hset operation recorded');

    like(
        exception { $redis->exec },
        qr/^\Q[exec] WRONGTYPE Operation against a key holding the wrong kind of value\E/,
        'a bad transaction results in an exception',
    );

    # we need to get a new redis client now -- see notes above
    $redis = $o->();

    is($redis->get('transaction_key_1'), 'foo', 'the first command was executed');

    cmp_deeply(
        { $redis->hgetall('transaction_key_3') },
        {
            a => '9',
            b => '2',
        },
        'commands after the error were still executed',
    );
}


done_testing;
