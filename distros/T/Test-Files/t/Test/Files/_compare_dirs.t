use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_UNDEF );

my ( $error, $expected, $file_list );
my $mock_this = mock $CLASS => (
  override => [
    _compare_files      => sub { [] },
    _dir_contains_ok    => sub { $file_list },
    _get_two_files_info => sub { shift->diag( $error ) },
    _show_failure       => sub {
      shift;
      my $err = sprintf( $FMT_UNDEF, $expected, '.+' ); like( shift, qr/$err/, 'failure reported' );
      return 0;
    },
    _show_result        => sub { is( !!@{ shift->diag }, !!@$error, 'result reported' ) },
  ]
);

plan( 4 );

subtest 'first directory undefined' => sub {
  plan( 2 );

  $expected = '\$expected_dir';
  ok( !$CLASS->_init->$METHOD, 'comparison failed' );
};

subtest 'second directory undefined' => sub {
  plan( 2 );

  $expected = '\$got_dir';
  ok( !$CLASS->_init->expected( 'x' )->$METHOD, 'comparison failed' );
};

path( $TEMP_DIR )->child( 'SUBDIR' )->mkdir;
path( $TEMP_DIR )->child( 'PLAIN_FILE' )->touch;
( $error, $expected, $file_list ) = ( [], undef, [ 'file' ] );
subtest 'directories identical' => sub {
  plan( 2 );

  is( $CLASS->_init->got( 'FIRST_DIR' )->expected( $TEMP_DIR )->$METHOD, 1, 'comparison performed' );
};

( $error, $expected, $file_list ) = ( [ 'ERROR' ], undef, [ 'file' ] );
subtest 'differences detected' => sub {
  plan( 2 );

  is( $CLASS->_init->got( 'FIRST_DIR' )->expected( $TEMP_DIR )->$METHOD, 1, 'comparison performed' );
};
