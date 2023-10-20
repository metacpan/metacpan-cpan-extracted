use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

plan( 1 );

ok( !exists( $main::{ CLASS } ), 'there is no class corresponding to this test file' );
