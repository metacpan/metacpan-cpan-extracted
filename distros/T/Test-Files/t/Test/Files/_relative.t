use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempfile => {};

plan( 2 );

is( $CLASS->_init->               $METHOD( $TEMP_FILE ), $TEMP_FILE,                            'base directory undefined' );

my $base = path( $TEMP_FILE )->dirname;
is( $CLASS->_init->base( $base )->$METHOD( $TEMP_FILE ), path( $TEMP_FILE )->relative( $base ), 'base directory defined' );
