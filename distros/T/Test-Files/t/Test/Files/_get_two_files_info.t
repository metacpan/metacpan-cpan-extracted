use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

const my $CONTENT => 'content';
const my $ERROR   => 'error';

my @result;
my $mock_this = mock $CLASS => ( override => [ _get_file_info => sub { @{ shift( @result ) } } ] );

plan( 2 );

subtest 'first file reading failed' => sub {
  plan( 2 );

  @result      = ( [ $ERROR, undef ], [ undef, $CONTENT ] );
  my $expected = [ undef, $CONTENT  ];
  my $self     = $CLASS->_init;

  is( [ $self->$METHOD( 'first_file', 'second_file', 'first_name', 'second_name' ) ], $expected, 'result value' );

  $expected = [ $ERROR ];
  is( $self->diag,                                                                    $expected, 'error message' );
};

subtest 'second file reading failed' => sub {
  plan( 2 );

  @result      = ( [ undef, $CONTENT ], [ $ERROR, undef ] );
  my $expected = [ $CONTENT, undef  ];
  my $self     = $CLASS->_init;

  is( [ $self->$METHOD( 'first_file', 'second_file', 'first_name', 'second_name' ) ], $expected, 'result value' );

  $expected = [ $ERROR ];
  is( $self->diag,                                                                    $expected, 'error message' );
};
