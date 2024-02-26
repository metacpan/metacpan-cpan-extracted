use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

my ( $diag, $error, $expected, $file_list );
my $mock_this = mock $CLASS => (
  override => [
    _compare_files          => sub { [] },
    _dir_contains_ok        => sub { ( [], $file_list ) },
    _get_two_files_info     => sub { $error },
    _show_failure           => sub { pass( 'failure reported' ); return },
    _show_result            => sub { is( !!shift, !!$expected, 'result reported' ); return },
    _validate_trailing_args => sub { $diag },
  ]
);

plan( 5 );

subtest 'trailing arguments invalid' => sub {
  plan( 2 );
  $diag = 'ERROR';
  is( $METHOD_REF->(), undef, 'comparison performed' );
};

$diag = undef;
subtest 'first directory undefined' => sub {
  plan( 2 );
  is( $METHOD_REF->(), undef, 'comparison performed' );
};

subtest 'second directory undefined' => sub {
  plan( 2 );
  is( $METHOD_REF->( 'FIRST_DIR' ), undef, 'comparison performed' );
};

path( $TEMP_DIR )->child( 'SUBDIR' )->mkdir;
path( $TEMP_DIR )->child( 'PLAIN_FILE' )->touch;
( $error, $expected, $file_list ) = ( [], 1, [ 'file' ] );
subtest 'directories identical' => sub {
  plan( 2 );
  is( $METHOD_REF->( 'FIRST_DIR', $TEMP_DIR ), undef, 'comparison performed' );
};

( $error, $expected, $file_list ) = ( [ 'ERROR' ], 0, [ 'file' ] );
subtest 'differences detected' => sub {
  plan( 2 );
  is( $METHOD_REF->( 'FIRST_DIR', $TEMP_DIR ), undef, 'comparison performed' );
};
