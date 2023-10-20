use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -target => 'Test::Expander';

plan( 2 );

ok(  exists( $main::{ CLASS } ),  'there is a class corresponding to this test file' );
ok( !exists( $main::{ METHOD } ), 'there is no method corresponding to this test file' );
