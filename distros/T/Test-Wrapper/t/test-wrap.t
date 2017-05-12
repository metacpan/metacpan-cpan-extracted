use strict;
use warnings;

use Test::More tests => 7;

use Test::More;
use Test::Wrapper;

test_wrap( 'like' ); 

my $t = like "foo" => qr/bar/;

ok ! $t->is_success;

test_wrap( 'is_deeply', prefix => 'w_' );

$t = w_is_deeply( { a => 1 }, { a => 2 } );

ok ! $t->is_success;

is $t->test_name => 'is_deeply', 'test_name';
is_deeply [ $t->test_args ], [ { a => 1 }, { a => 2 } ], 'test_args';

is_deeply [ 1..5 ], [1..5], 'original test left alone';

# test with many functions

test_wrap( [ qw/ is unlike / ] );

my $t1 = is 'a', 'b';
my $t2 = unlike "Babar" => qr/Mickey Mouse/;

ok !$t1, "'is' failed";
ok $t2, "'unlike' passed";

