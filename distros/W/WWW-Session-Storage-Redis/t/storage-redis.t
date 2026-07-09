#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 5;

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw(output failure_output todo_output);

my $have_redis = eval { require Cache::Redis; 1 } ? 1 : 0;

SKIP: {

    skip "Cache::Redis not installed" => 5 unless $have_redis;

    use_ok('WWW::Session::Storage::Redis');

    my $storage;
    eval {
        $storage =
            WWW::Session::Storage::Redis->new({
                server => "127.0.0.1:6379"
            });
    };

    skip "Could not connect to Redis server" => 4 unless $storage and !$@;

    subtest "Never expire (-1)" => sub {
        my $sid     = 'test1';
        my $expires = -1;
        my $string  = "Test 123";

        ok( $storage->save( $sid, $expires, $string ), 'Save works' );

        sleep 1;

        my $rstring = $storage->retrieve($sid);

        is( $rstring, $string, "String preserved" );

        $storage->delete($sid);

        $rstring = $storage->retrieve($sid);
        is( $rstring, undef, "Session data removed after delete()" );
    };

    subtest "Expire in 10 seconds" => sub {
        my $sid     = 'test2';
        my $expires = 10;
        my $string  = "Test 123";

        ok( $storage->save( $sid, $expires, $string ), 'Save works' );

        sleep 1;

        my $rstring = $storage->retrieve($sid);

        is( $rstring, $string, "String preserved before TTL expires" );

        $storage->delete($sid);

        $rstring = $storage->retrieve($sid);
        is( $rstring, undef, "Session data removed after delete()" );
    };

    subtest "Expires after TTL" => sub {
        my $sid     = 'test3';
        my $expires = 1;
        my $string  = "Test 123";

        ok( $storage->save( $sid, $expires, $string ), 'Save works' );

        sleep 3;

        my $rstring = $storage->retrieve($sid);

        is( $rstring, undef, "Session data gone after TTL expired" );

        $rstring = $storage->retrieve($sid);
        is( $rstring, undef, "Still gone on a second retrieve" );
    };

    subtest "utf-8" => sub {
        my $sid     = 'test4';
        my $expires = 10;
        my $string  = "Test 123 îâăȚȘș";

        ok( $storage->save( $sid, $expires, $string ), 'Save works' );

        my $rstring = $storage->retrieve($sid);

        is( $rstring, $string, "String with wide characters preserved" );

        $storage->delete($sid);
        $rstring = $storage->retrieve($sid);
        is( $rstring, undef, "Session data removed after delete()" );
    };
}
