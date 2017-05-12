#!perl -T

use Test::More tests => 4;

use TryCatch::Error;

my $e = TryCatch::Error->new;

is( $e->get_value, 0, 'Correct value' );
is( $e->get_message, '', 'Correct message' );


$e->set_value( 1 );
$e->set_message( 'An error' );

is( $e->get_value, 1, 'Correct value' );
is( $e->get_message, 'An error', 'Correct message' );
