use Test::More tests => 2;

BEGIN {
use_ok( 'Weaving::Tablet' );
}

BEGIN {
use_ok( 'Weaving::Tablet::Tk' );
}

diag( "Testing Weaving::Tablet $Weaving::Tablet::VERSION" );
