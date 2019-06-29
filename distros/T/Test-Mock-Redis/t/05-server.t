#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Mock::Redis;


=pod
x   AUTH
x   ECHO
x   PING
x   QUIT
o   SELECT  <-- TODO: complain about invalid values?

    BGREWRITEAOF
    BGSAVE
    CONFIG GET
    CONFIG RESETSTAT
    CONFIG SET
    DBSIZE
    DEBUG OBJECT
    DEBUG SEGFAULT
x   FLUSHALL
x   FLUSHDB
o   INFO
x   LASTSAVE
    MONITOR
x   SAVE
o   SHUTDOWN
    SLAVEOF
    SYNC
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

    ok($r->ping, 'ping returns PONG');
    ok($r->select($_), "select returns true for $_") for 0..15;

    $r->select(0);

    # TODO: do we care?
    eval{ $r->auth };
    like($@, qr/^\Q[auth] ERR wrong number of arguments for 'auth' command\E/, 'auth without a password dies');

    # as of redis 2.6 (?) this fails when auth is not enabled on the server
    # eval{ $r->auth('foo') };
    # like($@, qr/^\Q[auth] ERR Client sent AUTH, but no password is set\E/, 'auth when no password set dies');
    # however, emulating this behavior is not likely to be useful - better to silently
    # pretend that any auth worked than throw an error.

    for(0..15){
        $r->select($_);
        $r->set('foo', "foobar $_");
        is($r->get('foo'), "foobar $_");
    }

    ok($r->flushall);

    for(0..15){
        $r->select($_);
        ok(! $r->exists('foo'), "foo flushed from db$_");
    }

    for my $flush_db (0..15){
        for(0..15){
            $r->select($_);
            $r->set('foo', "foobar $_");
            is($r->get('foo'), "foobar $_");
        }

        $r->select($flush_db);
        $r->flushdb;

        ok(! $r->exists('foo'), "foo flushed from db$flush_db");

        for(0..15){
            next if $_ == $flush_db;
            $r->select($_);
            ok($r->exists('foo'), "foo not flushed from db$_");
        }
    }

    $r->select(0);  # go back to db0

    like($r->lastsave, qr/^\d+$/, 'lastsave returns digits');

    ok($r->save, 'save returns true');
    like($r->lastsave, qr/^\d+$/, 'lastsave returns digits');

    my $info = $r->info;
    is(ref $info, 'HASH', 'info returned a hash');

    #use Data::Dumper; diag Dumper $info;

    like($info->{run_id},qr/^[0-9a-f]{40}/, 'run_id is 40 random hex chars');

    for(0..14){
        is($info->{"db$_"}, 'keys=1,expires=0,avg_ttl=0', "db$_ info is correct");
    }
    # db15 was left with nothing in it, since it was the last one flushed
    is($info->{"db15"}, undef, 'info returns no data about databases with no keys');

    $r->setex("volitile-key-$_", 15, 'some value') for (1..5);


    like $r->info->{'db0'}, qr/^keys=6,expires=5,avg_ttl=\d+$/,
      'db0 info now has six keys and five expires';

    ok($r->quit, 'quit returns true');
    ok(!$r->quit, 'quit returns false the second time');

    ok(! $r->ping, 'ping returns false after we quit');

    my $type = ref $r;
    my $r2 = $type->new(server => $srv);

    ok($r2->ping, 'we can ping our new redis client');

    $r2->shutdown;  # doesn't return anything

    ok(! $r2->ping, 'ping returns false after we shutdown');
}


done_testing();


