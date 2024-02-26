use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_INVALID_ARGUMENT $FMT_INVALID_DIR $FMT_UNDEF );

const my $MISSING_FILE => 'MISSING_FILE';

plan( 6 );

my ( $expected, $valid_trailing_args );
my $mockThis = mock $CLASS => (
  override => [ _validate_trailing_args => sub { $valid_trailing_args ? () : 'ARG ERROR' } ]
);

$valid_trailing_args = undef;
is( $METHOD_REF->( 'ARRAY', $TEMP_DIR, [] ), 'ARG ERROR', 'invalid options' );

$valid_trailing_args = 1;

$expected = sprintf( $FMT_UNDEF, '\$dir', '.+' );
like( $METHOD_REF->( 'ARRAY', undef, [] ), qr/$expected/, 'directory undefined' );

$expected = sprintf( $FMT_INVALID_DIR, path( $TEMP_DIR )->child( $MISSING_FILE ) );
like( $METHOD_REF->( 'ARRAY', path( $TEMP_DIR )->child( $MISSING_FILE ), [] ), qr/$expected/, 'not a directory' );

$expected = sprintf( $FMT_INVALID_ARGUMENT, '.+', 'array reference', '2nd' );
like( $METHOD_REF->( 'ARRAY', $TEMP_DIR, {} ), qr/$expected/, 'file list has a wrong type' );

$expected = sprintf( $FMT_INVALID_ARGUMENT, '.+', 'code reference', '2nd' );
like( $METHOD_REF->( 'CODE', $TEMP_DIR, {} ), qr/$expected/, 'code reference has a wrong type' );

$expected = [ undef, path( $TEMP_DIR ), [], undef, undef ];
is( [ $METHOD_REF->( 'ARRAY', $TEMP_DIR, [] ) ], $expected, 'arguments are valid' );
