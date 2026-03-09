use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;
use Test::Expander::Constants qw( $FMT_INVALID_COLOR $FMT_UNKNOWN_OPTION );

plan( 4 );

my $expected;
my @args = ( {}, 'color' );

lives_ok  { $METHOD_REF->( @args ) }                'no colors defined';

$args[ 2 ] = { exported => 'black' };
lives_ok  { $METHOD_REF->( @args ) }                'valid color defined';

$args[ 2 ] = { exported => 'invalid' };
$expected   = sprintf( $FMT_INVALID_COLOR, '.+', '.+' );
throws_ok { $METHOD_REF->( @args ) } qr/$expected/, 'invalid color defined';

$args[ 2 ] = { exported => undef, unknown => 'invalid' };
$expected   = sprintf( $FMT_UNKNOWN_OPTION, '.+', '.+' );
throws_ok { $METHOD_REF->( @args ) } qr/$expected/, 'unknown color category';
