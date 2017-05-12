use strict;
use warnings;

use Test::More tests => 9;

use_ok 'Test::Parallel';

my $p = Test::Parallel->new();

$p->ok( sub { 1 }, "can do ok" );
$p->is( sub { 42 }, 42, "can do is" );
$p->isnt( sub { 42 }, 51, "can do isnt" );
$p->like( sub { "abc" }, qr{ab}, "can do like: match ab" );
$p->unlike( sub { "abc" }, qr{xy}, "can do unlike: match ab" );
$p->cmp_ok( sub { 'abc' },  'eq', 'abc', "can do cmp ok" );
$p->cmp_ok( sub { '1421' }, '==', 1_421, "can do cmp ok" );
$p->is_deeply( sub { [ 1 .. 15 ] }, [ 1 .. 15 ], "can do is_deeply" );

#$p->can_ok( sub { 'Test::More' }, 'add', 'can do can_ok' );
#$p->isa_ok( sub { return Test::Parallel->new() }, 'Test::Parallel', 'can do isa_ok' );

$p->done();
