#!/usr/bin/env perl

use warnings;
use strict;
use lib 't/tlib';
use Test::More;
use Test::Mock::Redis ();

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

foreach my $o (@redi){
    diag("testing $o") if $ENV{RELEASE_TESTING};

    my @lists = ( qw/ forward backward all / );

    for my $lname ( @lists ) {
        $o->rpush($lname, 'hello');
        $o->rpush($lname, 'hello');
        $o->rpush($lname, 'foo');
        $o->rpush($lname, 'hello');

        is_deeply(
            [ $o->lrange($lname, 0, -1) ],
            [ qw/
              hello
              hello
              foo
              hello
            / ],
            "list $lname as expected"
        );
    }

    is( $o->lrem('forward', 2, 'hello'), 2, 'two removed from forward list' );

    is_deeply(
        [ $o->lrange('forward', 0, -1) ],
        [ qw/
          foo
          hello
        / ],
        'forward list as expected'
    );

    is( $o->lrem('backward', -2, 'hello'), 2, 'two removed from backward list' );

    is_deeply(
        [ $o->lrange('backward', 0, -1) ],
        [ qw/
          hello
          foo
        / ],
        'backward list as expected'
    );

    is( $o->lrem('all', 0, 'hello'), 3, '3 removed from all list' );

    is_deeply(
        [ $o->lrange('all', 0, -1) ],
        [ qw/
          foo
        / ],
        'all list as expected'
    );
}


done_testing;

