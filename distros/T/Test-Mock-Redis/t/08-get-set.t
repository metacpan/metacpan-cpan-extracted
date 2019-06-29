#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Fatal 'exception';
use Test::Mock::Redis;
use Encode ();

=pod
x   APPEND
x   DECR
x   DECRBY
x   GET
    GETBIT
    GETRANGE
o   GETSET   <-- needs error for non-string value
x   INCR
x   INCRBY
x   MGET
x   MSET
x   MSETNX
x   SET
    SETBIT
x   SETNX
    SETRANGE
x   STRLEN
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

    ok(! $r->exists('foo'), 'foo does not exist yet');
    is($r->get('foo'), undef, "get on a key that doesn't exist returns undef");

    ok($r->set('foo', 'foobar'), 'can set foo');
    ok($r->set('bar', 'barfoo'), 'can set bar');
    ok($r->set('baz', 'bazbaz'), 'can set baz');

    is($r->get('foo'), 'foobar', 'can get foo');
    is($r->get('bar'), 'barfoo', 'can get bar');
    is($r->get('baz'), 'bazbaz', 'can get baz');

    is($r->type('foo'), 'string', 'type of foo is string');

    subtest 'set options' => sub {
        ok(! $r->set('foo', 'new_val', 'NX'), 'set takes NX option');
        is($r->get('foo'), 'foobar', 'value did not change because of NX');

        note 'Try again on new key';
        ok($r->set('oof', 'new_val', 'NX'), 'Testing NX on non-existent key');
        is($r->get('oof'), 'new_val', 'Successfully set key with NX');

        note 'Back to foo';
        ok($r->set('foo', 'new_val', 'XX'), 'set takes XX option');
        is($r->get('foo'), 'new_val', 'XX updates the value');

        ok($r->set('foo', 'foobar', 'EX' => 1000), 'set takes EX option');
        ok($r->ttl('foo') > 999 && $r->ttl('foo') <= 1000, 'EX sets TTL');

        note 'Now trying some combinations';
        ok($r->set('raboof', 'val', 'NX', EX => 10), 'Called set with NX and EX');
        is($r->get('raboof'), 'val', ' - created key');
        ok($r->ttl('raboof') > 9 && $r->ttl('raboof') <= 10, ' - set TTL');
        ok($r->set('raboof', 'bar', 'XX', EX => 20), 'Called set with XX and EX');
        is($r->get('raboof'), 'bar', ' - updated key');
        ok($r->ttl('raboof') > 19 && $r->ttl('raboof') <= 20, ' - reset TTL');

        like exception { $r->set('finaltest', 'baz', 'NX', 'XX') },
          qr/\[set\] ERR syntax error/,
          'Combining NX and XX is a syntax error';

        like exception { $r->set('raboof', 'val', 'EX', 100, 'PX', 10) },
          qr/^\[set\] ERR syntax error/,
          'Combining EX and PX is a syntax error';

        like exception { $r->set('raboof', 'val', 'EXX') },
          qr/^\[set\] ERR syntax error/,
          'Using unknown option is a syntax error';
    };

    ok(! $r->setnx('foo', 'foobar'), 'setnx returns false for existing key');
    ok($r->setnx('qux', 'quxqux'),   'setnx returns true for new key');

    is($r->incr('incr-test'),  1, 'incr returns  1 for new value');
    is($r->decr('decr-test'), -1, 'decr returns -1 for new value');

    is($r->incr('incr-test'),  2, 'incr returns  2 the next time');
    is($r->decr('decr-test'), -2, 'decr returns -2 the next time');

    is($r->incr('decr-test'), -1);
    is($r->incr('decr-test'),  0, 'decr returns 0 appropriately');

    is($r->decr('incr-test'), 1);
    is($r->decr('incr-test'), 0, 'incr returns 0 appropriately');

    is($r->incrby('incrby-test', 10),  10, 'incrby 10 returns incrby value for new value');
    is($r->decrby('decrby-test', 10), -10, 'decrby 10 returns decrby value for new value');

    is($r->decrby('incrby-test', 10), 0, 'incrby returns 0 appropriately');
    is($r->incrby('decrby-test', 10), 0, 'decrby returns 0 appropriately');

    is($r->incrby('incrby-test', -15), -15, 'incrby a negative value works');
    is($r->decrby('incrby-test', -15),   0, 'decrby a negative value works');

    is($r->append('append-test', 'foo'), 3, 'append returns length (for new)');
    is($r->append('append-test', 'bar'), 6, 'append returns length');
    is($r->append('append-test', 'baz'), $r->strlen('append-test'), 'strlen agrees with append');

    is($r->strlen('append-test'), 9, 'length of append-test key is now 9');

    is($r->append('append-test', Encode::encode( 'UTF-8', '€') ), 12, 'euro character (multi-byte) only counted by bytes');

    is($r->getset('foo', 'whee!'),  'foobar', 'getset returned old value of foo');
    is($r->getset('foo', 'foobar'), 'whee!',  'getset returned old value of foo again (so it must have been set)');


    is_deeply([$r->mget(qw/one two three/)], [undef, undef, undef], 'mget returns correct number of undefs');

    ok([$r->mset(one => 'fish', two => 'fish', red => 'herring')], 'true returned for Dr Seuss');

    is_deeply([$r->mget(qw/one two red blue/)], [qw/fish fish herring/, undef], 'mget returned Dr Seuss and undef');

    is_deeply([$r->mget(qw/two blue one red/)], [qw/fish/, undef, qw/fish herring/], 'mget likes order');

    ok( !$r->msetnx(blue => 'fish', red => 'fish'), 'msetnx fails if any key exists');

    is($r->get('red'), 'herring', 'msetnx left red alone');

    ok($r->del('red'), 'bye bye red');

    ok($r->msetnx(blue => 'fish', red => 'fish'), 'msetnx sets multiple keys');

    is_deeply([$r->mget(qw/one two red blue/)], [qw/fish fish fish fish/], 'all fish now');
}


=pod
TODO: {
    local $TODO = "no setbit/getbit yet";

    # set the first 8 bits to 0, and the next 8 to 1
    ok(! $r->setbit('bits', $_, 0) for(0..7);
    ok(! $r->setbit('bits', $_, 1) for(8..15);

    ok(! $r->getbit('bits', $_), "got 0 at bit offset $_") for(0..7);
    ok($r->getbit('bits', $_), "got 1 at bit offset $_") for(8..15);
    ok(! $r->getbit('bits', 16), "got 1 at bit offset $_");
};
=cut


done_testing();
