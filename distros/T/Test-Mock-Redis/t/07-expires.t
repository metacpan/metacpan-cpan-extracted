#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Mock::Redis ();

=pod
x   SETEX
x   EXPIRE
x   EXPIREAT
x   PERSIST
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

    ok($r->set('foo', 'foobar'), 'can set foo');
    ok($r->set('bar', 'barfoo'), 'can set bar');
    ok($r->set('baz', 'bazbaz'), 'can set baz');

    ok(! $r->expire('quizlebub', 1), "expire on a key that doesn't exist returns false");
    ok($r->expire('bar', 1), 'expire on a key that exists returns true');

    sleep 2;

    is_deeply([ sort $r->keys('*') ], [ qw(baz foo) ], 'expired key removed from KEYS list');

    ok(! $r->exists('bar'), 'bar expired');

    ok(! $r->expireat('quizlebub', time + 1), "expireat on a key that doesn't exist returns false");
    ok($r->expireat('baz', time + 1), 'expireat on a key that exists returns true');

    sleep 2;

    ok(! $r->exists('baz'), 'baz expired');

    ok($r->setex('foo', 1, 'foobar'), 'set foo again returns a true value');

    sleep 2;

    ok(! $r->exists('foo'), 'foo expired');

    ok($r->setex('foo', 2, 'foobar'), 'set foo again returns a true value');
    ok($r->persist('foo'), 'persist for a key that exists returns true');

    ok(! $r->persist('quizlebub'), "persist returns false for a key that doesn't exist");

    sleep 3;

    is($r->get('foo'), 'foobar', 'foo persisted');
}

done_testing();
