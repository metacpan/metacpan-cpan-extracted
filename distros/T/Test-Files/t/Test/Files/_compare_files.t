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

subtest 'compare existence only' => sub {
  plan( 3 );

  $expected = [ sprintf( $FMT_SECOND_FILE_ABSENT, $FIRST_FILE, $SECOND_FILE ) ];
  is( $METHOD_REF->( 0, 1, { EXISTENCE_ONLY => 1 }, $FIRST_FILE, $SECOND_FILE ), $expected, 'first file missing' );

  $expected = [ sprintf( $FMT_FIRST_FILE_ABSENT,  $FIRST_FILE, $SECOND_FILE ) ];
  is( $METHOD_REF->( 1, 0, { EXISTENCE_ONLY => 1 }, $FIRST_FILE, $SECOND_FILE ), $expected, 'second file missing' );

  $expected = [];
  is( $METHOD_REF->( 1, 1, { EXISTENCE_ONLY => 1 }, $FIRST_FILE, $SECOND_FILE ), $expected, 'both files exist' );
};

subtest 'compare size' => sub {
  plan( 2 );

  $expected = [ sprintf( $FMT_DIFFERENT_SIZE, $FIRST_FILE, $SECOND_FILE, 1, 0 ) ];
  is( $METHOD_REF->( 1, 0, { SIZE_ONLY => 1 }, $FIRST_FILE, $SECOND_FILE ), $expected, 'different size' );

  $expected = [];
  is( $METHOD_REF->( 1, 1, { SIZE_ONLY => 1 }, $FIRST_FILE, $SECOND_FILE ), $expected, 'equal size' );
};

subtest 'compare content' => sub {
  plan( 2 );

  ok(  scalar( @{ $METHOD_REF->( '1', '0', { STYLE => 'OldStyle'}, $FIRST_FILE, $SECOND_FILE ) } ), 'different content' );
  ok( !scalar( @{ $METHOD_REF->( '1', '1', { CONTEXT => 2 },       $FIRST_FILE, $SECOND_FILE ) } ), 'identical content' );
};
