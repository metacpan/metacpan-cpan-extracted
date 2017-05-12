# $Id: 00-load.t 4 2006-05-12 20:18:10Z rmuhle $

use Test::More tests => 2;

BEGIN {
	use_ok( 'classes' );
}

diag( "Testing classes $classes::VERSION, Perl $], $^X" );
ok($classes::VERSION);
