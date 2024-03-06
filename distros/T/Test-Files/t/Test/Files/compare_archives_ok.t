use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

plan( 2 );

subtest success => sub {
  plan( 3 );

  my $mock_this = mock $CLASS => (
    override => [
      _compare_dirs           => sub { pass( 'content compared' ) },
      _compare_metadata       => sub { pass( 'metadata compared' ); shift },
      _extract                => sub { shift },
      _validate_trailing_args => sub { my ( $self ) = @_; $self->options( { EXTRACT => sub {}, FILTER => qr/./ } ) },
    ]
  );

  ok( $METHOD_REF->( 'got_archive', 'reference_archive' ), 'executed' );
};

subtest failure => sub {
  plan( 4 );

  subtest 'invalid arguments' => sub {
    plan( 1 );

    my $mock_this = mock $CLASS => (
      override => [
        _show_failure           => sub {},
        _validate_trailing_args => sub { shift->diag( [ 'ERROR' ] ) },
      ]
    );

    ok( !$METHOD_REF->( 'got_archive', 'reference_archive' ), 'executed' );
  };

  subtest 'metadata differs or cannot be extracted' => sub {
    plan( 1 );

    my $mock_this = mock $CLASS => (
      override => [
        _compare_metadata       => sub { shift->diag( [ 'ERROR' ] ) },
        _show_failure           => sub {},
        _validate_trailing_args => sub { shift },
      ]
    );

    ok( !$METHOD_REF->( 'got_archive', 'reference_archive' ), 'executed' );
  };

  subtest 'content differs' => sub {
    plan( 1 );

    my $mock_this = mock $CLASS => (
      override => [
        _compare_metadata       => sub { shift },
        _extract                => sub { shift->diag( undef ) },
        _show_failure           => sub {},
        _validate_trailing_args => sub { shift },
      ]
    );

    ok( !$METHOD_REF->( 'got_archive', 'reference_archive' ), 'executed' );
  };

  subtest 'content cannot be extracted' => sub {
    plan( 1 );

    my $mock_this = mock $CLASS => (
      override => [
        _compare_metadata       => sub { shift },
        _extract                => sub { shift->diag( [ 'ERROR' ] ) },
        _show_failure           => sub {},
        _validate_trailing_args => sub { shift },
      ]
    );

    ok( !$METHOD_REF->( 'got_archive', 'reference_archive' ), 'executed' );
  };
};
