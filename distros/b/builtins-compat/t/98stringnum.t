use strict;
use warnings;
use Test::More;
use builtins::compat;

ok created_as_number( 3 );
ok created_as_number( 3.1 );
ok created_as_number( -3 );
ok created_as_number( -3.1 );
ok created_as_number( 0 );
ok created_as_number( 1e8 );
ok created_as_number( '6' * '6' * '6' );

ok ! created_as_number( '3' );
ok ! created_as_number( '3.1' );
ok ! created_as_number( '-3' );
ok ! created_as_number( '-3.1' );
ok ! created_as_number( '0' );
ok ! created_as_number( '1e8' );
ok ! created_as_number( 'Hello world' );
ok ! created_as_number( '' );
ok ! created_as_number( [] );
ok ! created_as_number( qr// );
ok ! created_as_number( {} );
ok ! created_as_number( \0 );
ok ! created_as_number( \1 );
ok ! created_as_number( false );
ok ! created_as_number( true );
ok ! created_as_number( undef );

ok created_as_string( '3' );
ok created_as_string( '3.1' );
ok created_as_string( '-3' );
ok created_as_string( '-3.1' );
ok created_as_string( '0' );
ok created_as_string( '1e8' );
ok created_as_string( 'Hello world' );
ok created_as_string( '' );

ok ! created_as_string( [] );
ok ! created_as_string( qr// );
ok ! created_as_string( {} );
ok ! created_as_string( \0 );
ok ! created_as_string( \1 );
ok ! created_as_string( false );
ok ! created_as_string( true );
ok ! created_as_string( undef );
ok ! created_as_string( 3 );
ok ! created_as_string( 3.1 );
ok ! created_as_string( -3 );
ok ! created_as_string( -3.1 );
ok ! created_as_string( 0 );
ok ! created_as_string( 1e8 );
ok ! created_as_string( '6' * '6' * '6' );

done_testing;
