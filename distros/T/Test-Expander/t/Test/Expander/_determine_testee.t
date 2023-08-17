use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -method => undef;

ok(  exists( $main::{ CLASS  } ),   'class determined' );
ok( !exists( $main::{ METHOD } ),   'no method determined' );
ok( !exists( $ENV{ NEW_ENV_VAR } ), 'environment variable unset due to undefined value from .env file' );

done_testing();
