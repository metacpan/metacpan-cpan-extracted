use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_INVALID_ARGUMENT $FMT_INVALID_DIR $FMT_UNDEF );

plan( 6 );

subtest 'invalid options' => sub {
  plan( 2 );

  my $expected = 'ARG ERROR';
  my $mockThis = mock $CLASS => ( override => [ _validate_trailing_args => sub { shift->diag( [ $expected ] ) } ] );
  my $self     = $CLASS->_init;
  is( $self->$METHOD( 'ARRAY', $TEMP_DIR, [] ), undef,         'empty result' );
  is( $self->diag,                              [ $expected ], 'error message' );
};

subtest 'directory undefined' => sub {
  plan( 2 );

  my $expected = sprintf( $FMT_UNDEF, '\$dir', '.+' );
  my $self     = $CLASS->_init;
  is  ( $self->$METHOD( 'ARRAY' ), undef,             'empty result' );
  like( $self->diag,               [ qr/$expected/ ], 'error message' );
};

subtest 'not a directory' => sub {
  plan( 2 );

  const my $MISSING_FILE => 'MISSING_FILE';
  my $expected = sprintf( $FMT_INVALID_DIR, path( $TEMP_DIR )->child( $MISSING_FILE ) );
  my $self     = $CLASS->_init;
  is  ( $self->$METHOD( 'ARRAY', path( $TEMP_DIR )->child( $MISSING_FILE ), [] ), undef,             'empty result' );
  like( $self->diag,                                                              [ qr/$expected/ ], 'error message' );
};

subtest 'file list has a wrong type' => sub {
  plan( 2 );

  my $expected = sprintf( $FMT_INVALID_ARGUMENT, '.+', 'array reference', '2nd' );
  my $self     = $CLASS->_init;
  is  ( $self->$METHOD( 'ARRAY', $TEMP_DIR, {} ), undef,             'empty result' );
  like( $self->diag,                              [ qr/$expected/ ], 'error message' );
};

subtest 'code reference has a wrong type' => sub {
  plan( 2 );

  my $expected = sprintf( $FMT_INVALID_ARGUMENT, '.+', 'code reference', '2nd' );
  my $self     = $CLASS->_init;
  is  ( $self->$METHOD( 'CODE', $TEMP_DIR, {} ), undef,             'empty result' );
  like( $self->diag,                             [ qr/$expected/ ], 'error message' );
};

subtest 'arguments are valid' => sub {
  plan( 2 );

  my $expected = [ 'file' ];
  my $self     = $CLASS->_init;
  is( $self->$METHOD( 'ARRAY', $TEMP_DIR, $expected ), $expected, 'expected result' );
  is( $self->diag,                                     [],        'no error message' );
};
