use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;
use Test::Expander::Constants qw( $FMT_MISSING_TDT );

plan( 2 );

my $success;
my $mockPathTiny = mock 'Path::Tiny' => ( override => [ slurp => sub { die( "ERROR\n" ) unless $success; 'A' . $/ . 'B' } ] );

$success = 1;
is( $METHOD_REF->( 'FILE' ), [ qw( A B ) ], 'success' );

$success = 0;
my $expected = sprintf( $FMT_MISSING_TDT, $TEST_FILE =~ s/\.t$/.tdt/r, 'ERROR' );
throws_ok { $METHOD_REF->( 'FILE' ) } qr/$expected/, 'failure';
