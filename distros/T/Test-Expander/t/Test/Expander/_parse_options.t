use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -target => undef;

ok( !exists( $main::{ CLASS } ), 'no class determined' );

done_testing();
