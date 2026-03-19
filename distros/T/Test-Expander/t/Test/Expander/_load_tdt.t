use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;
use Test::Expander::Constants qw( $FALSE $FMT_MISSING_TDT $TRUE );

plan( 2 );

my $success;
my $mockPathTiny = mock 'Path::Tiny' => ( override => [ slurp => sub { die( "ERROR\n" ) unless $success; 'A' . $/ . 'B' } ] );

$success = $TRUE;
is( $METHOD_REF->( 'FILE' ), [ qw( A B ) ], 'success' );

$success = $FALSE;
my $expected = sprintf( $FMT_MISSING_TDT, $TEST_FILE =~ s/\.t$/.tdt/r, 'ERROR' );
throws_ok { $METHOD_REF->( 'FILE' ) } qr/$expected/, 'failure';
