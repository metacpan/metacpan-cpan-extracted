use warnings;
use strict;

use lib 't/lib';
use Test::More tests => 9;

use_ok('FunctionWipeout');
ok( !FunctionWipeout->can('foo'),
    'imported function removed' );
ok( !FunctionWipeout->can('bar'),
    'previously declared function removed' );
ok( FunctionWipeout->can('baz'),
    'later declared function still exists' );
is( FunctionWipeout->baz, 23,
    'removed functions still bound' );
ok( FunctionWipeout->can('qux'),
    '-except flag keeps import' );
is( FunctionWipeout->qux, 17,
    'kept import still works' );
ok( $FunctionWipeout::foo,
    'non-code symbol was not removed' );
is( $FunctionWipeout::foo, 777,
    'non-code symbol still has correct value' );
