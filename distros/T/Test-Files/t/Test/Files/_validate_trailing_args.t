use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

use Test::Files::Constants qw( $DIRECTORY_OPTIONS $FMT_INVALID_ARGUMENT );

my ( $diag, %options );
my $mockThis = mock $CLASS => ( override => [ _validate_options => sub { shift->diag( $diag )->options( \%options ) } ] );

const my $DEFAULT => $DIRECTORY_OPTIONS;

plan( 6 );

subtest 'trailing arguments omitted' => sub {
  plan( 4 );

  ( $diag, %options ) = ( [] );
  my $self = $CLASS->_init;

  isa_ok( $self->$METHOD( [], $DEFAULT ), $CLASS );
  is( $self->diag,    $diag,    'no error message' );
  is( $self->name,    '',       'empty test name' );
  is( $self->options, $DEFAULT, 'default options applied' );
};

subtest 'options omitted, test name supplied' => sub {
  plan( 4 );

  ( $diag, %options ) = ( [] );
  my $self = $CLASS->_init;

  isa_ok( $self->$METHOD( [ 'title' ], $DEFAULT ), $CLASS );
  is( $self->diag,    $diag,    'no error message' );
  is( $self->name,    'title',  'test name detected' );
  is( $self->options, $DEFAULT, 'default options applied' );
};

subtest 'options supplied' => sub {
  plan( 3 );

  ( $diag, %options ) = ( [ 'ERROR' ] );
  my $self = $CLASS->_init;

  isa_ok( $self->$METHOD( [ { X => 0 } ], $DEFAULT ), $CLASS );
  is( $self->diag, $diag, 'invalid option detected' );

  subtest "'SIZE_ONLY' and test name supplied" => sub {
    plan( 4 );

    ( $diag, %options ) = ( [], SIZE_ONLY => 1 );
    my $self = $CLASS->_init;

    isa_ok( $self->$METHOD( [ \%options, 'title' ], $DEFAULT ), $CLASS );
    is( $self->diag,    $diag,                   'no error message' );
    is( $self->name,    'title',                 'test name detected' );
    is( $self->options, { %$DEFAULT, %options }, 'options updated' );
  };
};

subtest 'filter and title supplied, options updated' => sub {
  plan( 4 );

  $diag      = [];
  my $filter = sub {};
  my $self   = $CLASS->_init;

  isa_ok( $self->$METHOD( [ $filter, 'title' ], $DEFAULT ), $CLASS );
  is( $self->diag,    $diag,                            'no error message' );
  is( $self->name,    'title',                          'test name detected' );
  is( $self->options, { %$DEFAULT, FILTER => $filter }, 'options updated' );
};

my $expected = sprintf( $FMT_INVALID_ARGUMENT, '.+', 'hash reference / code reference / string', '3rd' );
my $self     = $CLASS->_init;

isa_ok( $self->$METHOD( [ [] ], $DEFAULT ), $CLASS );
like( $self->diag, [ qr/$expected/ ], 'invalid argument type' );
