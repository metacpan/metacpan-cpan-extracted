#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'FTNDB' );
    use_ok( 'FTNDB::Nodelist' );
    use_ok( 'FTNDB::Command::create' );
    use_ok( 'FTNDB::Command::drop' );
}

diag( "Testing FTN DB Application $FTNDB::VERSION, Perl $], $^X" );
