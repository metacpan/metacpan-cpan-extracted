use Test::More tests => 2;

use Tk;
use strict;

use_ok( 'Tk::MARC::Editor' );
is( $Tk::MARC::Editor::VERSION,'1.0', 'Ok' );

