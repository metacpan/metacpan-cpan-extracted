use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_FAILED_TO_SEE );

const my $TEMP_PATH  => path( $TEMP_DIR );
const my $TEMP_PATH1 => $TEMP_PATH->child( 'DIR1' );
const my $TEMP_PATH2 => $TEMP_PATH->child( 'DIR2' );

my $expected;
my $mock_this = mock $CLASS => (
  override => [
    _show_result => sub {
      my ( undef, @messages ) = @_;
      if ( ref( $expected->[ 0 ] ) ne 'Regexp' ) {
        is( \@messages, $expected, 'result reported' );
      }
      else {
        while ( my ( $index, $got ) = each( @messages ) ) {
          like( $got, $expected->[ $index ], "result line $index reported" );
        }
      }
    }
  ]
);

foreach my $dir_num ( 1 .. 2 ) {
  $TEMP_PATH->child( "DIR$dir_num", 'SUBDIR'       )->mkdir;
  foreach my $sub_dir ( [], [ 'SUBDIR' ] ) {
    $TEMP_PATH->child( "DIR$dir_num", @$sub_dir, 'SAME_CONTENT' )->spew( "CONTENT1\n"          );
    $TEMP_PATH->child( "DIR$dir_num", @$sub_dir, 'DIFF_CONTENT' )->spew( "CONTENT2 $dir_num\n" );
    $TEMP_PATH->child( "DIR$dir_num", @$sub_dir, 'DIFF_SIZE'    )->spew( '.' x $dir_num . "\n" );
  }
  $TEMP_PATH->child( "DIR$dir_num", @$_, "SOLE_FILE$dir_num" )->touch foreach [], [ 'SUBDIR' ];
}

plan( 4 );

subtest 'backward compatibility (compare_dirs_ok)' => sub {
  plan( 4 );
  my @expected = (
    join( '.+' , map { $TEMP_PATH->child( "DIR$_", 'DIFF_CONTENT' ) } 1 .. 2 ),
    join( '.+' , map { $TEMP_PATH->child( "DIR$_", 'DIFF_SIZE'    ) } 1 .. 2 ),
    $TEMP_PATH1->child( qw( SOLE_FILE2 ) )->stringify,
  );
  $expected = [ map { qr/$_/s } @expected ];
  lives_ok { $METHOD_REF->( "$TEMP_PATH1", "$TEMP_PATH2" ) } 'executed';
};

subtest 'backward compatibility (compare_dirs_filter_ok)' => sub {
  plan( 3 );
  my @expected = (
    join( '.+' , map { $TEMP_PATH->child( "DIR$_", 'DIFF_SIZE' ) } 1 .. 2 ),
    $TEMP_PATH1->child( qw( SOLE_FILE2 ) )->stringify,
  );
  $expected = [ map { qr/$_/s } @expected ];
  lives_ok { $METHOD_REF->( "$TEMP_PATH1", "$TEMP_PATH2", { FILTER => sub { s/\s\d//r } } ) } 'executed';
};

subtest 'compare existence recursively' => sub {
  plan( 2 );
  $expected = [ sort map { sprintf( $FMT_FAILED_TO_SEE, $TEMP_PATH1->child( @$_, 'SOLE_FILE2' ) ) } [], [ 'SUBDIR' ] ];
  lives_ok { $METHOD_REF->( $TEMP_PATH1, $TEMP_PATH2, { EXISTENCE_ONLY => 1, RECURSIVE => 1 } ) } 'executed';
};

subtest 'compare size recursively' => sub {
  plan( 5 );
  my @expected = (
    join( '.+' , map { $TEMP_PATH->child( "DIR$_", 'DIFF_SIZE' ) } 1 .. 2 ),
    join( '.+' , map { $TEMP_PATH->child( "DIR$_", 'SUBDIR', 'DIFF_SIZE' ) } 1 .. 2 ),
    map { $TEMP_PATH1->child( @$_, 'SOLE_FILE2' )->stringify } [], [ 'SUBDIR' ],
  );
  $expected = [ map { qr/$_/ } @expected ];
  lives_ok { $METHOD_REF->( $TEMP_PATH1, $TEMP_PATH2, { SIZE_ONLY => 1, RECURSIVE => 1 } ) } 'executed';
};
