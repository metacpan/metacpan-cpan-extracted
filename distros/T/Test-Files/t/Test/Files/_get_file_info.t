use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_ABSENT $FMT_ABSENT_WITH_ERROR $FMT_UNDEF );

const my $SUB => 'some::subroutine';
my $mock_this = mock $CLASS => ( override => [ _get_caller_sub => sub { $SUB } ] );

my $expected;
my $self = $CLASS->_init;

plan( 3 );

$expected = [ sprintf( $FMT_UNDEF, '$file', $SUB ), undef ];
is( [ $self->$METHOD( undef, '$file' ) ], $expected, 'file undefined' );

const my $CONTENT => "line 0\nline 1\n";

SKIP: {
  const my $FILE          => path( $TEMP_DIR )->child( 'file' );
  const my $UNTESTABLE_OS => $^O =~ /^(?:MSWin32|cygwin|(?:free|open)bsd|solaris)$/ || !path( '/dev/null' )->exists;
  skip "$^O does not support special device files" if $UNTESTABLE_OS;

  subtest 'file name supplied' => sub {
    plan( 5 );
    subtest 'file is absent' => sub {
      plan( 3 );

      $expected = [ sprintf( $FMT_ABSENT, $FILE ), undef ];
      is( [ $self->$METHOD( $FILE, '$file' ) ], $expected, 'file does not exist' );

      subtest 'file is a cpecial one' => sub {
        plan( 2 );

        $expected = [ sprintf( $FMT_ABSENT, '/dev/null' ), undef ];
        $self->options( { EXISTENCE_ONLY => 0 } );
        is( [ $self->$METHOD( '/dev/null', '$file' ) ], $expected, 'get content' );

        $expected = [ undef, 1 ];
        $self->options( { EXISTENCE_ONLY => 1 } );
        is( [ $self->$METHOD( '/dev/null', '$file' ) ], $expected, 'check existence' );
      };

      $expected = [ sprintf( $FMT_ABSENT, $TEMP_DIR ), undef ];
      $self->options( {} );
      is( [ $self->$METHOD( $TEMP_DIR, '$file' ) ], $expected, 'file is a directory' );
    };

    $FILE->spew( $CONTENT );

    $self->options( { EXISTENCE_ONLY => 1 } );
    ok( [ $self->$METHOD( $FILE, '$file' ) ],            'file existence' );

    $expected = [ undef, length( $CONTENT ) ];
    $self->options( { SIZE_ONLY => 1 } );
    is( [ $self->$METHOD( $FILE, '$file' ) ], $expected, 'file size' );

    subtest 'filter omitted, reading failed' => sub {
      plan( 2 );

      $FILE->chmod( 0 );
      $self->options( {} );
      my $expected = sprintf( $FMT_ABSENT_WITH_ERROR, $FILE, '.+' );
      my @got      = $self->$METHOD( $FILE, '$file' );
      like( $got[ 0 ], qr/$expected/, 'error message' );
      is  ( $got[ 1 ], undef,         'file content' );
    };

    $FILE->chmod( 'u+r' );
    $expected = [ undef, "line 0\n" ];
    $self->options( { FILTER => sub { /0/ ? $_ : undef } } );
    is( [ $self->$METHOD( $FILE, '$file' ) ], $expected, 'filter supplied, reading succeeded' );
  };
}

subtest 'scalar reference supplied' => sub {
  plan( 2 );

  $expected = [ undef, length( $CONTENT ) ];
  $self->options( { SIZE_ONLY => 1 } );
  is( [ $self->$METHOD( \$CONTENT, '$expected' ) ], $expected, 'content size' );

  $expected = [ undef, $CONTENT ];
  $self->options( {} );
  is( [ $self->$METHOD( \$CONTENT, '$expected' ) ], $expected, 'content returned' );
};
