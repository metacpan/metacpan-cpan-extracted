use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

use Test::Files::Constants qw( $DIRECTORY_OPTIONS $FMT_INVALID_ARGUMENT );

my ( $diag, %options );
my $mockThis = mock $CLASS => ( override => [ _validate_options => sub { ( $diag, %options ) } ] );

const my $DEFAULT => $DIRECTORY_OPTIONS;
my $expected;

plan( 5 );

$expected = [ undef, $DEFAULT ];
is( [ $METHOD_REF->( [],          $DEFAULT ) ], $expected,      'trailing arguments omitted' );

$expected = [ undef, $DEFAULT, 'title' ];
is( [ $METHOD_REF->( [ 'title' ], $DEFAULT ) ], $expected, 'options omitted, title supplied' );

subtest 'options supplied' => sub {
  plan( 2 );

  ( $diag, %options ) = ( 'ERROR' );
  $expected           = [ $diag ];
  is( [ $METHOD_REF->( [ { X => 0 } ], $DEFAULT ) ],         $expected, 'invalid option detected' );

  ( $diag, %options ) = ( undef, SIZE_ONLY => 1 );
  $expected           = [ $diag, { %$DEFAULT, %options }, 'title' ];
  is( [ $METHOD_REF->( [ \%options, 'title' ], $DEFAULT ) ], $expected, 'options updated' );
};

my $filter          = sub {};
( $diag, %options ) = ( undef, FILTER => $filter );
$expected           = [ undef, { %$DEFAULT, %options }, 'title' ];
is  ( [ $METHOD_REF->( [ $filter, 'title' ], $DEFAULT ) ], $expected,  'filter and title supplied, options updated' );

$expected = sprintf( $FMT_INVALID_ARGUMENT, '.+', 'hash reference / code reference / string', '3rd' );
like( $METHOD_REF->( [ [] ], $DEFAULT ),                qr/$expected/, 'invalid argument type' );
