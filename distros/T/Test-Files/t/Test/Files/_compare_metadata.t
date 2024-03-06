use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

use Test::Files::Constants qw( $FMT_CANNOT_GET_METADATA );

plan( 4 );

subtest 'got metadata cannot be acquired' => sub {
  plan( 2 );

  my $mock_this = mock $CLASS => (
    override => [
      diag => sub {
        my ( $self, $messages ) = @_;
        my $expected = sprintf( $FMT_CANNOT_GET_METADATA, 'got_archive', '.*' );
        like( $messages->[ 0 ], qr/$expected/, 'exception raised' );
        return $self;
      }
    ]
  );

  my $self = $CLASS->_init->got( 'got_archive')->expected( 'reference_archive' )
    ->options( { META_DATA => sub { die} } );
  isa_ok( $self->$METHOD, $CLASS );
};

subtest 'expected metadata cannot be acquired' => sub {
  plan( 2 );

  my $mock_this = mock $CLASS => (
    override => [
      diag => sub {
        my ( $self, $messages ) = @_;
        my $expected = sprintf( $FMT_CANNOT_GET_METADATA, 'reference_archive', '.*' );
        like( $messages->[ 0 ], qr/$expected/, 'exception raised' );
        return $self;
      }
    ]
  );

  my $self = $CLASS->_init->got( 'got_archive')->expected( 'reference_archive' )
    ->options( { META_DATA => sub { die if shift eq 'reference_archive' } } );
  isa_ok( $self->$METHOD, $CLASS );
};

subtest 'identical metadata' => sub {
  plan( 2 );

  my $self = $CLASS->_init->got( 'got_archive')->expected( 'reference_archive' )->options( { META_DATA => sub {} } );
  isa_ok( $self->$METHOD, $CLASS );
  is( $self->diag, [], 'no errors detected' );
};

subtest 'different metadata' => sub {
  plan( 3 );

  my $mock_this = mock $CLASS => ( override => [ is => sub ( $$;$@ ) { pass( 'differences displayed' ) } ] );

  my $self = $CLASS->_init->got( 'got_archive')->expected( 'reference_archive' )
    ->options( { META_DATA => sub { shift } } );
  isa_ok( $self->$METHOD, $CLASS );
  is( $self->diag, undef, 'special handling provided' );
};
