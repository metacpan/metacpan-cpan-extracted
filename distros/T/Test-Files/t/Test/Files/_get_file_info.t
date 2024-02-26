use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander -tempdir => {};

use Test::Files::Constants qw( $FMT_ABSENT $FMT_ABSENT_WITH_ERROR $FMT_UNDEF );

const my $SUB => 'some::subroutine';
my $mock_this = mock $CLASS => ( override => [ _get_caller_sub => sub { $SUB } ] );

my $expected;

plan( 3 );

$expected = [ sprintf( $FMT_UNDEF, '$file', $SUB ), undef ];
is( [ $METHOD_REF->( undef, sub {}, '$file' ) ], $expected, 'file undefined' );

const my $CONTENT => "line 0\nline 1\n";

SKIP: {
  const my $FILE          => path( $TEMP_DIR )->child( 'file' );
  const my $UNTESTABLE_OS => $^O eq 'MSWin32' || !path( '/dev/null' )->exists;
  skip "$^O does not support special device files" if $UNTESTABLE_OS;

  subtest 'file name supplied' => sub {
    subtest 'file is absent' => sub {
      plan( 3 );

      $expected = [ sprintf( $FMT_ABSENT, $FILE ), undef ];
      is( [ $METHOD_REF->( $FILE, {}, '$file' ) ], $expected, 'file does not exist' );

      subtest 'file is a cpecial one' => sub {
        plan( 2 );
        my $options;

        $options  = { EXISTENCE_ONLY => 0 };
        $expected = [ sprintf( $FMT_ABSENT, '/dev/null' ), undef ];
        is( [ $METHOD_REF->( '/dev/null', $options, '$file' ) ], $expected, 'get content' );

        $options  = { EXISTENCE_ONLY => 1 };
        $expected = [ undef, 1 ];
        is( [ $METHOD_REF->( '/dev/null', $options, '$file' ) ], $expected, 'check existence' );
      };

      $expected = [ sprintf( $FMT_ABSENT, $TEMP_DIR ), undef ];
      is( [ $METHOD_REF->( $TEMP_DIR, {}, '$file' ) ], $expected, 'file is a directory' );
    };

    $FILE->spew( $CONTENT );

    ok( [ $METHOD_REF->( $FILE, { EXISTENCE_ONLY => 1 }, '$file' ) ],       'file existence' );

    $expected = [ undef, length( $CONTENT ) ];
    is( [ $METHOD_REF->( $FILE, { SIZE_ONLY => 1 }, '$file' ) ], $expected, 'file size' );

    subtest 'filter omitted, reading failed' => sub {
      plan( 2 );
      $FILE->chmod( 0 );

      my $expected = sprintf( $FMT_ABSENT_WITH_ERROR, $FILE, '.+' );
      my @got      = $METHOD_REF->( $FILE, {}, '$file' );
      like( $got[ 0 ], qr/$expected/, 'error message' );
      is  ( $got[ 1 ], undef,         'file content' );
    };

    $FILE->chmod( 'u+r' );
    $expected = [ undef, "line 0\n" ];
    is(
      [ $METHOD_REF->( $FILE, { FILTER => sub { /0/ ? $_ : undef } }, '$file' ) ],
      $expected,
      'filter supplied, reading succeeded'
    );
  };
}

subtest 'scalar reference supplied' => sub {
  plan( 2 );

  $expected = [ undef, length( $CONTENT ) ];
  is( [ $METHOD_REF->( \$CONTENT, { SIZE_ONLY => 1 }, '$expected' ) ], $expected, 'content size' );

  $expected = [ undef, $CONTENT ];
  is( [ $METHOD_REF->( \$CONTENT, {}, '$expected' ) ],                 $expected, 'content returned' );
};
