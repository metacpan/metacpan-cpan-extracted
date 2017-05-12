use Test::More tests => 3;

use_ok( 'UNIVERSAL::can' );

diag( "Testing UNIVERSAL::can $UNIVERSAL::can::VERSION, Perl $], $^X" );

ok( ! defined &main::can, 'UNIVERSAL::can() should not export can()' );

package not_main;

use UNIVERSAL::can 'can';

::ok( defined &not_main::can, '.. but should export it when requested' );
