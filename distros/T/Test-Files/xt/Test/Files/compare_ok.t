use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -color => { exported => 'cyan', unexported => 'magenta' }, -tempdir => {};

my ( $args_valid, $expected, $file_diff, $files_info );
my $mock_this = mock $CLASS => (
  override => [
    _compare_files          => sub { $file_diff },
    _get_two_files_info     => sub { $files_info },
    _show_failure           => sub { is( [ @_[ 1 .. $#_ ] ], $expected, 'failure reported' ); return },
    _show_result            => sub { is( [ @_[ 2 .. $#_ ] ], $expected, 'comparison result reported' ); return },
    _validate_trailing_args => sub { $args_valid ? ( undef, $_[ 0 ]->[ 0 ], $_[ 0 ]->[ 1 ] ) : 'ARG ERROR' },
  ]
);

plan( 4 );                                                  ## no critic (ProhibitMagicNumbers)

subtest 'invalid optional arguments' => sub {
  plan( 2 );                                                ## no critic (ProhibitMagicNumbers)
  ( $args_valid, $expected, $file_diff, $files_info ) = ( 0, [ 'ARG ERROR' ], [], [] );
  is( $METHOD_REF->( 'got_file', 'expected_file' ), undef, 'executed' );
};

subtest 'file info cannot be gathered' => sub {
  plan( 2 );                                                ## no critic (ProhibitMagicNumbers)
  ( $args_valid, $expected, $file_diff, $files_info ) = ( 1, [ 'INFO ERROR' ], [], [ 'INFO ERROR' ] );
  is( $METHOD_REF->( 'got_file', 'expected_file' ), undef, 'executed' );
};

subtest 'expected file passed, differences detected' => sub {
  plan( 2 );                                                ## no critic (ProhibitMagicNumbers)
  ( $args_valid, $expected, $file_diff, $files_info ) = ( 1, [ 'DIFF ERROR' ], [ 'DIFF ERROR' ], [] );
  is( $METHOD_REF->( 'got_file', 'expected_file' ), undef, 'executed' );
};

subtest 'expected content passed, differences detected' => sub {
  plan( 2 );                                                ## no critic (ProhibitMagicNumbers)
  ( $args_valid, $expected, $file_diff, $files_info ) = ( 1, [ 'DIFF ERROR' ], [ 'DIFF ERROR' ], [] );
  is( $METHOD_REF->( 'got_file', \'expected_content' ), undef, 'executed' );
};
