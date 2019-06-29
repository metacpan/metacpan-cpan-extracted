#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mock::Redis ();

=pod
    ZADD
    ZCARD
    ZCOUNT
    ZINCRBY
    ZINTERSTORE
    ZRANGE
    ZRANGEBYSCORE
    ZRANK
    ZREM
    ZREMRANGEBYRANK
    ZREMRANGEBYSCORE
    ZREVRANGE
    ZREVRANGEBYSCORE
    ZREVRANK
    ZSCORE
    ZUNIONSTORE
=cut

my $r = Test::Mock::Redis->new;

diag('TODO');
ok(1, 'placeholder to keep Test::More happy');

done_testing();

