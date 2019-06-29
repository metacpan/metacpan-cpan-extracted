#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Fatal;
use Test::Mock::Redis;

=pod
x   HDEL
x   HEXISTS
x   HGET
x   HGETALL
x   HINCRBY
x   HKEYS
x   HLEN
x   HMGET
o   HMSET
x   HSET
    HSETNX
    HVALS
=cut

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

foreach my $r (@redi){
    diag("testing $r") if $ENV{RELEASE_TESTING};

    ok ! $r->hexists('hash', 'foo'), "hexists on an empty hash returns false";

    ok ! $r->hexists('hash', 'foo'), "hexists on the same empty hash returns false proving there was no autovivification";

    is $r->hget('hash', 'foo'), undef, "hget for a hash that doesn't exist is undef";

    is_deeply([sort $r->hkeys('hash')], [], "hkeys returned no keys for a hash that doesn't exist");

    is $r->hset('hash', 'foo', 'foobar'), 1, "hset returns 1 when it's happy";

    is $r->hget('hash', 'foo'), 'foobar', "hget returns the value we just set";

    is $r->type('hash'), 'hash', "type of key hash is hash";

    is $r->hget('hash', 'bar'), undef, "hget for a hash field that doesn't exist is undef";

    ok $r->hset('hash', 'bar', 'foobar'), "hset returns true when it's happy";

    is $r->hlen('hash'), 2, "hlen counted two keys";

    is_deeply([sort $r->hkeys('hash')], [qw/bar foo/], 'hkeys returned our keys');

    is $r->hset('hash', 'bar', 'barfoo'), 0, "hset returns 0 when they field already existed";

    is $r->hget('hash', 'bar'), 'barfoo', "hget returns the value we just set";

    ok $r->set('hash', 'blarg'), "set returns true when we squash a hash";

    is $r->get('hash'), 'blarg', "even though it squashed it";

    like exception { $r->hset('hash', 'foo', 'foobar') },
        qr/^\Q[hset] WRONGTYPE Operation against a key holding the wrong kind of value\E/,
        "hset throws error when we overwrite a string with a hash";

    ok ! $r->hexists('blarg', 'blorf'), "hexists on a hash that doesn't exist returns false";

    like exception { $r->hexists('hash', 'blarg') },
        qr/^\Q[hexists] WRONGTYPE Operation against a key holding the wrong kind of value\E/,
        "hexists on a field that's not a hash throws error";

    $r->del('hash');

    ok $r->hset('hash', 'foo', 'foobar'), "hset returns true when it's happy";

    is $r->hexists('hash', 'foo'), 1, "hexists returns 1 when it's true";

    ok ! $r->hdel('blarg', 'blorf'), "hdel on a hash that doesn't exist returns false";
    ok ! $r->hdel('hash', 'blarg'),  "hdel on a hash field that doesn't exist returns false";

    ok $r->hdel('hash', 'foo'), "hdel returns true when it's happy";

    ok ! $r->hexists('hash', 'foo'), "hdel really deleted the field";
    is $r->hexists('hash', 'foo'), 0, "hexists returns 0 when field is not in the hash";

    is $r->hlen('hash'), 0, "hlen counted zarro keys";

    is_deeply([sort $r->hkeys('hash')], [], "hkeys returned no keys for an empty hash");

    $r->set('not a hash', 'foo bar');

    like exception { $r->hkeys('not a hash') },
         qr/^\Q[hkeys] WRONGTYPE Operation against a key holding the wrong kind of value\E/,
         "hkeys on key that isn't a hash throws error";

    # OK seems inconsistient
    is $r->hmset('hash', qw/foo bar bar baz baz qux qux quux quux quuux/), 'OK', "hmset returns OK if it set some stuff";

    is_deeply { $r->hgetall('hash') }, { foo => 'bar', bar => 'baz', baz => 'qux', qux => 'quux', quux => 'quuux' },
        "hget all returned our whole hash";

    is_deeply { $r->hgetall("I don't exist") }, { }, "hgetall on non-existent key is empty";

    like exception { $r->hgetall('not a hash') },
         qr/^\Q[hgetall] WRONGTYPE Operation against a key holding the wrong kind of value\E/,
         "hgetall on key that isn't a hash throws error";


    is_deeply [sort $r->hvals('hash')], [sort qw/bar baz qux quux quuux/],
        "hvals all returned all values";

    is_deeply [ $r->hvals("I don't exist") ], [ ], "hvals on non-existent key returned an empty list";

    $r->set('not a hash', 'foo bar');

    like exception { $r->hvals('not a hash') },
         qr/^\Q[hvals] WRONGTYPE Operation against a key holding the wrong kind of value\E/,
         "hvals on key that isn't a hash throws error";


    is_deeply [ $r->hmget('hash', qw/foo bar baz/) ], [ qw/bar baz qux/ ],
        "hmget returns requested values";

    is_deeply [ $r->hmget('hash', qw/blarg foo bar baz blorf/) ], [ undef, qw/bar baz qux/, undef ],
        "hmget returns undef for missing values";

    is_deeply [ $r->hmget('hash', qw/blarg blorf/) ], [ undef, undef ],
        "hmget returns undef even if all values are missing";

    like exception { $r->hincrby('hash', 'foo') },
        qr/^\Q[hincrby] ERR wrong number of arguments for 'hincrby' command\E/,
        "hincerby dies when called with the wrong number of arguments";

    like exception { $r->hincrby('hash', 'foo', 1) },
        qr/^\Q[hincrby] ERR hash value is not an integer\E/,
         "hincrby dies when a non-integer is incremented";

    is $r->hincrby('hash', 'incrme', 1), 1, "incrby 1 on a value that doesn't exist returns 1";
    is $r->hincrby('hash', 'incrmf', 2), 2, "incrby 2 on a value that doesn't exist returns 2";

    is $r->hincrby('hash', 'incrmf', -1), 1, "incrby returns value resulting from increment";

    is $r->hset('hash', 'emptystr', ''), 1, "can set hash value to empty string";

    like exception { $r->hincrby('hash', 'emptystr', 1) },
        qr/^\Q[hincrby] ERR hash value is not an integer\E/,
         "hincrby dies when an empty string is incremented";
}


done_testing();
