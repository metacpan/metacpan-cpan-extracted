use strict;
use warnings;
use Test::More;
use builtins::compat;

ok is_bool( true );
ok is_bool( false );
ok is_bool( 0==0 );
ok is_bool( 0==1 );
ok is_bool( !!1 );
ok is_bool( !!0 );

ok ! is_bool( undef );
ok ! is_bool( 0 );
ok ! is_bool( 1 );
ok ! is_bool( '0' );
ok ! is_bool( '1' );
ok ! is_bool( '' );
ok ! is_bool( \0 );
ok ! is_bool( \1 );
ok ! is_bool( [] );
ok ! is_bool( {} );

done_testing;
