#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Fatal;
use Test::Mock::Redis;

=pod
x   SADD
x   SCARD
x   SDIFF
x   SDIFFSTORE
x   SINTER
x   SINTERSTORE
x   SISMEMBER
x   SMEMBERS
x   SMOVE
x   SPOP
x   SRANDMEMBER
x   SREM
x   SUNION
x   SUNIONSTORE
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

my @members = (qw/foo bar baz qux quux quuux/);

foreach my $r (@redi){
    diag("testing $r") if $ENV{RELEASE_TESTING};


    is        $r->srandmember('noset'),         undef, "srandmember for a set that doesn't exist returns undef";
    is        $r->spop('noset'),                undef, "spop for a set that doesn't exist returns undef";
    is        $r->scard('noset'),                   0, "scard for a set that doesn't exist returns 0";
    is        $r->srem('noset', 'foo'),             0, "srem for a set that doesn't exist returns 0";
    is        $r->smove('noset', 'set', 'foo'),     0, "smove for sets that don't exist returns 0";
    is        $r->sismember('noset', 'foo'),        0, "sismember for a set that doesn't exist returns 0";
    is_deeply [$r->smembers('noset')],             [], "smembers for a set that doesn't exist returns an empty array";

    is $r->sadd('set', 'foo'),  1, "sadd returns 1 when element is new to the set";
    is $r->sadd('set', 'foo'),  0, "sadd returns 0 when element is already in the set";
    is $r->scard('set'),        1, "scard returns size of set";

    is $r->sadd('set', 'bar'),  1, "sadd returns 1 when element is new to the set";
    is $r->scard('set'),        2, "scard returns size of set";

    is $r->sismember('set', 'foo'), 1, "sismember returns 1 for a set element that exists";
    is $r->sismember('set', 'baz'), 0, "sismember returns 0 for a set element that doesn't exist";


    is_deeply [sort $r->smembers('set')], [qw/bar foo/], "smembers returns all members of the set";

    is $r->srem('set', 'bar'), 1, "srem returns 1 when it removes an element";

    is $r->sadd('set', $_), 1, "srem returns 1 when it adds a new element to the set"
        for (grep { $_ ne 'foo'} @members);

    is $r->type('set'), 'set', "our set has type set";

    my $randmember = $r->srandmember('set');
    ok $randmember, "srandmember returned something";
    ok grep { $_ eq $randmember } $r->smembers('set'), "srandmember returned a member";

    while($r->scard('set')){
        my $popped = $r->spop('set');
        ok $popped, "spopped something";
        ok grep { $_ eq $popped } @members, "spopped a member";
        is $r->sismember('set', $popped), 0, "spop removed $popped";
    }

    # set has been emptied.  Put some stuff in it again
    is $r->sadd('set', $_), 1, "srem returns 1 when it adds a new element to the set"
        for (@members);

    is $r->sadd('otherset', $_), 1, "srem returns 1 when it adds a new element to the set"
        for (qw/foo bar baz/);

    is $r->sadd('anotherset', $_), 1, "srem returns 1 when it adds a new element to the set"
        for (qw/bar baz qux/);

    is_deeply [sort $r->sinter('set', 'otherset')], [qw/bar baz foo/], "sinter returns all members in common";

    is_deeply [sort $r->sinter('set', 'otherset', 'anotherset')], [qw/bar baz/],
        "sinter returns all members in common for multiple sets";

    is_deeply [$r->sinter('set', 'emptyset')], [], "sinter returns empty list";
    is_deeply [$r->sinter('set', 'otherset', 'emptyset')], [], "sinter returns empty list with multiple sets";

    is $r->sinterstore('destset', 'set', 'otherset'), 3, "sinterstore returns cardinality of intersection";
    is_deeply [sort $r->smembers('destset')], [sort $r->sinter('set', 'otherset')], "sinterstore stored the correct result";

    is $r->sinterstore('destset', 'set', 'emptyset'), 0, "cardinality of empty intersection is zero";
    is_deeply [sort $r->smembers('destset')], [sort $r->sinter('set', 'emptyset')], "sinterstore stored the correct result";

    is $r->sinterstore('destset', 'set', 'otherset', 'anotherset'), 2, "sinterstore returns cardinality of intersection";
    is_deeply [sort $r->smembers('destset')], [sort $r->sinter('set', 'otherset', 'anotherset')], "sinterstore stored the correct result";

    is $r->sadd('otherset', $_), 1, "srem returns 1 when it adds a new element to the set"
        for (qw/oink bah neigh/);

    is_deeply [sort $r->sunion('set', 'otherset')],   [sort @members, qw/oink bah neigh/], "sunion returns all members of two sets";
    is_deeply [sort $r->sunion('set', 'anotherset')], [sort @members], "sunion returns all members of two sets";

    is $r->sunionstore('destset', 'set', 'otherset'), @members + 3, "sunionstore returns cardinality of union";
    is_deeply [sort $r->smembers('destset')], [sort $r->sunion('set', 'otherset')], "sunionstore stored the correct result";

    is $r->sunionstore('destset', 'set', 'emptyset'), @members, "cardinality of empty union is same as carindality of set";
    is_deeply [sort $r->smembers('destset')], [sort $r->sunion('set', 'emptyset')], "sunionstore stored the correct result";

    is $r->sunionstore('destset', 'set', 'otherset', 'anotherset'), @members + 3, "sunion returns cardinality of union";
    is_deeply [sort $r->smembers('destset')], [sort $r->sunion('set', 'otherset', 'anotherset')], "sunionstore stored the correct result";

    is_deeply [sort $r->sdiff('set', 'otherset')], [qw/quuux quux qux/], "sdiff removed members correctly";
    is_deeply [sort $r->sdiff('set', 'otherset', 'anotherset')], [qw/quuux quux/], "sdiff removed members correctly";

    is $r->sdiffstore('destset', 'set', 'otherset'), 3, "sdiffstore returnes cardinality of difference";
    is_deeply [sort $r->smembers('destset')], [sort $r->sdiff('set', 'otherset')], "sdiffstore stored the correct result";

    is $r->sdiffstore('destset', 'set', 'otherset', 'anotherset'), 2, "sdiffstore returnes cardinality of difference";
    is_deeply [sort $r->smembers('destset')], [sort $r->sdiff('set', 'otherset', 'anotherset')], "sdiffstore stored the correct result";

    # cardinality of the difference with the empty set is the same as what we started with
    is $r->sdiffstore('destset', 'set', 'emptyset'), $r->scard('set'), "sdiffstore returnes cardinality of difference";
    is_deeply [sort $r->smembers('destset')], [sort $r->smembers('set')], "sdiffstore stored the correct result";

    is $r->smove('otherset', 'set', 'oink'), 1, "smove returns true if it moved an element succesfully";
    is $r->sismember('set', 'oink'), 1, "oink moved to set";
    is $r->sismember('otherset', 'oink'), 0, "oink removed from otherset";

    is $r->smove('otherset', 'set', 'meow'), 0, "smove returns false if it failed to move an element";

    is $r->smove('notaset', 'otherset', 'foo'), 0, "smove returns false when source doesn't exist";

    $r->set('justakey', 'foobar');

    like exception { $r->smove('justakey', 'set', 'foo') },
        qr/^\Q[smove] WRONGTYPE Operation against a key holding the wrong kind of value\E/,
         "smove dies when source isn't a set";

    like exception { $r->smove('set', 'justakey', 'foo') },
        qr/^\Q[smove] WRONGTYPE Operation against a key holding the wrong kind of value\E/,
         "smove dies when dest isn't a set";

    is $r->smove('otherset', 'newset', 'foo'), 1, "smove returns true when destination doesn't exist";
    is $r->type('newset'), 'set', "newset sprang into existence";
}

done_testing();

