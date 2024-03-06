use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

use Test::Files::Constants qw( $FMT_CANNOT_CREATE_DIR $FMT_CANNOT_EXTRACT );

plan( 3 );

subtest 'cannot create working directory' => sub {
  plan( 2 );

  my $mock_Path_Tiny = mock 'Path::Tiny' => ( override => [ mkdir => sub { die } ] );
  my $mock_this      = mock $CLASS => (
    override => [
      diag => sub {
        my ( $self, $messages ) = @_;
        my $expected = sprintf( $FMT_CANNOT_CREATE_DIR, '.*got_archive', '.*' );
        like( $messages->[ 0 ], qr/$expected/, 'exception raised' );
        return $self;
      }
    ]
  );

  my $self = $CLASS->_init->got( 'got_archive' )->expected( 'expected_archive' )->options( { EXTRACT => sub {} } );
  isa_ok( $self->$METHOD, $CLASS );
};

subtest 'cannot extract archive content' => sub {
  plan( 2 );

  my $mock_this = mock $CLASS => (
    override => [
      diag => sub {
        my ( $self, $messages ) = @_;
        my $expected = sprintf( $FMT_CANNOT_EXTRACT, 'got_archive', '.*got_archive', '.*' );
        like( $messages->[ 0 ], qr/$expected/, 'exception raised' );
        return $self;
      }
    ]
  );

  my $self = $CLASS->_init->got( 'got_archive' )->expected( 'expected_archive' )->options( { EXTRACT => sub { die } } );
  isa_ok( $self->$METHOD, $CLASS );
};

subtest success => sub {
  plan( 3 );

  my $self = $CLASS->_init->got( 'got_archive' )->expected( 'expected_archive' )
    ->options( { EXTRACT => sub { path( 'content' )->touch } } );
  isa_ok( $self->$METHOD, $CLASS );
  ok( $self->base->child( $_, 'content' )->exists, "extracted from '$_'" ) foreach qw( got_archive expected_archive );
};
