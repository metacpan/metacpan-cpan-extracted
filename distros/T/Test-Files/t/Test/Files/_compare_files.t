use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_DIFFERENT_SIZE $FMT_FIRST_FILE_ABSENT $FMT_SECOND_FILE_ABSENT );

const my $FIRST_FILE  => path( $TEMP_DIR )->child( 'first_file' );
const my $SECOND_FILE => path( $TEMP_DIR )->child( 'second_file' );

plan( 3 );

my $expected;
my $self = $CLASS->_init;

subtest 'compare existence only' => sub {
  plan( 3 );

  $self->options( { EXISTENCE_ONLY => 1 } );

  $expected = [ sprintf( $FMT_FIRST_FILE_ABSENT,  $FIRST_FILE, $SECOND_FILE ) ];
  is( $self->diag( [] )->$METHOD( 0, 1, $FIRST_FILE, $SECOND_FILE )->diag, $expected, 'second file missing' );

  $expected = [ sprintf( $FMT_SECOND_FILE_ABSENT, $FIRST_FILE, $SECOND_FILE ) ];
  is( $self->diag( [] )->$METHOD( 1, 0, $FIRST_FILE, $SECOND_FILE )->diag, $expected, 'first file missing' );

  $expected = [];
  is( $self->diag( [] )->$METHOD( 1, 1, $FIRST_FILE, $SECOND_FILE )->diag, $expected, 'both files exist' );
};

subtest 'compare size' => sub {
  plan( 2 );

  $self->options( { SIZE_ONLY => 1 } );

  $expected = [ sprintf( $FMT_DIFFERENT_SIZE, $FIRST_FILE, $SECOND_FILE, 1, 0 ) ];
  is( $self->diag( [] )->$METHOD( 1, 0, $FIRST_FILE, $SECOND_FILE )->diag, $expected, 'different size' );

  $expected = [];
  is( $self->diag( [] )->$METHOD( 1, 1, $FIRST_FILE, $SECOND_FILE )->diag, $expected, 'equal size' );
};

subtest 'compare content' => sub {
  plan( 2 );

  $self->options( { CONTEXT => 2, STYLE => 'OldStyle'} );

  isnt( $self->diag( [] )->$METHOD( '1', '0', $FIRST_FILE, $SECOND_FILE )->diag, [], 'different content' );
  is  ( $self->diag( [] )->$METHOD( '1', '1', $FIRST_FILE, $SECOND_FILE )->diag, [], 'identical content' );
};
