use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

my ( $args_valid, $diff, $info_valid );
my $mock_this = mock $CLASS => (
  override => [
    _compare_files          => sub { my ( $self ) = @_; $self->diag( $diff ); $self },
    _get_two_files_info     => sub { shift->diag( $info_valid ? [] : [ 'INFO ERROR' ] ) },
    _show_failure           => sub {},
    _show_result            => sub { !@{ shift->diag } },
    _validate_trailing_args => sub { shift->diag( $args_valid ? [] : [ 'ARGS ERROR' ] ) },
  ]
);

plan( 4 );

subtest 'invalid optional arguments' => sub {
  plan( 2 );

  my $self = $CLASS->_init;
  ( $args_valid, $diff, $info_valid ) = ( 0, [], 1 );
  ok( !$self->$METHOD( 'got_file', 'expected_file' ), 'failed' );
  is( $self->diag, [ 'ARGS ERROR' ],                  'failure reported' );
};

subtest 'file info cannot be gathered' => sub {
  plan( 2 );

  my $self = $CLASS->_init;
  ( $args_valid, $diff, $info_valid ) = ( 1, [], 0 );
  ok( !$self->$METHOD( 'got_file', 'expected_file' ), 'failed' );
  is( $self->diag, [ 'INFO ERROR' ],                  'failure reported' );
};

subtest 'expected file passed, differences detected' => sub {
  plan( 2 );

  my $self = $CLASS->_init;
  ( $args_valid, $diff, $info_valid ) = ( 1, [ 'DIFF' ],  1 );
  ok( !$self->$METHOD( 'got_file', 'expected_file' ), 'failed' );
  is( $self->diag, [ 'DIFF' ],                        'differences reported' );
};

subtest 'expected content passed, differences detected' => sub {
  plan( 2 );

  my $self = $CLASS->_init;
  ( $args_valid, $diff, $info_valid ) = ( 1, [ 'DIFF' ],  1 );
  ok( !$self->$METHOD( 'got_file', \'expected_file' ), 'failed' );
  is( $self->diag, [ 'DIFF' ],                         'differences reported' );
};
