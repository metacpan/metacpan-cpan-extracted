#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use WebService::Tumblr;

my ( $hash, $value );

$hash = {qw/ a 1 b 2 c 3 d 4 e 5 /};

is( $value = WebService::Tumblr::hash_refactor( hash => $hash, key => 'a', else => [qw/ w x y z /] ), 1 );
cmp_deeply( $hash, {qw/ a 1 b 2 c 3 d 4 e 5 /} );
is( $value = WebService::Tumblr::hash_refactor( hash => $hash, key => 'w', else => [qw/ d e /] ), 4 );
cmp_deeply( $hash, {qw/ w 4 a 1 b 2 c 3 d 4 e 5 /} );
is( $value = WebService::Tumblr::hash_refactor( hash => $hash, key => 'w', else => [qw/ d e /], delete => 1 ), 4 );
cmp_deeply( $hash, {qw/ w 4 a 1 b 2 c 3 /} );

done_testing;
