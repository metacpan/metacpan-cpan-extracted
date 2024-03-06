use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

use Test::Files::Constants qw(
  $DIRECTORY_OPTIONS $FMT_FILTER_ISNT_CODEREF $FILE_OPTIONS $FMT_INVALID_NAME_PATTER $FMT_INVALID_OPTIONS $FILE_OPTIONS
);

my ( $expected, $self );

plan( 2 );

subtest failure => sub {
  plan( 3 );

  const my $DEFAULT => $DIRECTORY_OPTIONS;

  subtest 'invalid option' => sub {
    plan( 2 );

    isa_ok( $self = $CLASS->_init->options( { X => 0 } )->$METHOD( $DEFAULT ), [ $CLASS ],    'executed' );

    $expected = sprintf( $FMT_INVALID_OPTIONS, 'X' );
    is( $self->diag,                                                           [ $expected ], 'detected' );
  };

  subtest 'filter is not a code reference' => sub {
    plan( 2 );

    isa_ok( $self = $CLASS->_init->options( { FILTER => 0 } )->$METHOD( $DEFAULT ), [ $CLASS ],        'executed' );

    $expected = sprintf( $FMT_FILTER_ISNT_CODEREF, '.+' ) =~ s/([()])/\\$1/gr;
    like( $self->diag,                                                              [ qr/$expected/ ], 'detected' );
  };

  subtest 'invalid name pattern' => sub {
    plan( 2 );

    isa_ok( $self = $CLASS->_init->options( { NAME_PATTERN => '[' } )->$METHOD( $DEFAULT ), [ $CLASS ],        'executed' );

    $expected = sprintf( $FMT_INVALID_NAME_PATTER, '\[', '.+', '.+' );
    like( $self->diag,                                                                      [ qr/$expected/ ], 'detected' );
  };
};

subtest success => sub {
  plan( 2 );

  subtest 'both filter and name pattern supplied' => sub {
    plan( 3 );

    const my $DEFAULT => $DIRECTORY_OPTIONS;

    my $filter = sub {};
    isa_ok(
      $self = $CLASS->_init->options( { FILTER => $filter, NAME_PATTERN => '..' } )->$METHOD( $DEFAULT ),
                        [ $CLASS ],                                             'executed'
    );
    is( $self->diag,    [],                                                     'no errors' );
    is( $self->options, { %$DEFAULT, FILTER => $filter, NAME_PATTERN => '..' }, 'arguments determined' );
  };

  subtest 'both filter and name pattern omitted' => sub {
    plan( 3 );

    const my $DEFAULT => $FILE_OPTIONS;

    isa_ok( $self = $CLASS->_init->options( {} )->$METHOD( $DEFAULT ), [ $CLASS ], 'executed' );
    is( $self->diag,                                                   [],         'no errors' );
    is( $self->options,                                                $DEFAULT,   'arguments determined' );
  };
};
