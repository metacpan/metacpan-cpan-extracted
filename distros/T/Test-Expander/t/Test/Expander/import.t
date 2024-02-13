use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

my ( @functions, @variables );
BEGIN {
  use Const::Fast;
  use File::Temp qw( tempdir tempfile );
  use Path::Tiny qw( cwd path );
  use Test2::Tools::Explain;
  use Test2::V0;
  @functions = (
    @{ Const::Fast::EXPORT },
    @{ Test2::Tools::Explain::EXPORT },
    @{ Test2::V0::EXPORT },
    qw( tempdir tempfile ),
    qw( cwd path ),
    qw( BAIL_OUT dies_ok is_deeply lives_ok new_ok require_ok use_ok ),
  );
  @variables = qw( $CLASS $METHOD $METHOD_REF $TEMP_DIR $TEMP_FILE $TEST_FILE );
}

use Term::ANSIColor           qw( colored );
use Scalar::Readonly          qw( readonly_off );
use Test::Builder::Tester     tests => @functions + @variables + ( exists( $ENV{ HARNESS_PERL_SWITCHES } ) ? 12 : 17 );
# use Test::Builder::Tester     tests => @functions + @variables + 17;

use Test::Expander            -target   => 'Test::Expander',
                              -tempdir  => { CLEANUP => 1 },
                              -tempfile => { UNLINK  => 1 };
use Test::Expander::Constants qw(
  $FMT_INVALID_DIRECTORY $FMT_INVALID_VALUE $FMT_SET_TO $FMT_REQUIRE_DESCRIPTION $FMT_UNKNOWN_OPTION $NOTE
);

foreach my $function ( sort @functions ) {
  my $title = "$CLASS->can('$function')";
  test_out( "ok 1 - $title" );
  can_ok( $CLASS, $function );
  test_test( $title );
}

foreach my $variable ( sort @variables ) {
  my $title = "$CLASS exports '$variable'";
  test_out( "ok 1 - $title" );
  ok( eval( "defined( $variable )" ), $title );             ## no critic (ProhibitStringyEval)
  test_test( $title );
}

my ( $title, $expected );

$title    = "invalid value type of '-builtins'";
$expected = $FMT_INVALID_VALUE =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( -builtins => [] ) } qr/$expected/, $title;
test_test( $title );

$title    = 'invalid type of a particular builtin mock';
$expected = $FMT_INVALID_VALUE =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( -builtins => { xxx => 'yyy' } ) } qr/$expected/, $title;
test_test( $title );

$title    = "invalid value type of '-lib'";
$expected = $FMT_INVALID_VALUE =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( -lib => {} ) } qr/$expected/, $title;
test_test( $title );

$title    = "invalid directory type within '-lib'";
$expected = $FMT_INVALID_DIRECTORY =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( -lib => [ {} ] ) } qr/$expected/, $title;
test_test( $title );

$title    = "invalid directory value within '-lib'";
$expected = $FMT_INVALID_DIRECTORY =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( -lib => [ 'ref(' ] ) } qr/$expected/, $title;
test_test( $title );

path( $TEMP_DIR )->child( 'my_root' )->mkdir;
path( $TEMP_DIR )->child( qw( my_root foo.pm ) )->spew( "package foo;\n1;\n" );
$title = "valid value of '-lib' containing expression to be substituted, '-bail' set (successfully executed)";
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
{
  my $mock_importer = mock 'Importer'  => ( override => [ import_into     => sub {} ] );
  my $mock_test2    = mock 'Test2::V0' => ( override => [ import          => sub {} ] );
  my $mock_this     = mock $CLASS      => ( override => [ _export_symbols => sub {} ] );
  is( $CLASS->$METHOD( -lib => [ 'path( $TEMP_DIR )->child( qw( my_root ) )->stringify' ], -bail => 1 ), undef, $title );
}
test_test( $title );

$title = sprintf( $FMT_REQUIRE_DESCRIPTION, 'foo', '' );
test_out( "ok 1 - $title" );
require_ok( 'foo', $title );
test_test( $title );

$title    = "invalid value of '-method'";
$expected = $FMT_INVALID_VALUE =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( -method => {} ) } qr/$expected/, $title;
test_test( $title );

$title    = "invalid value of '-tempdir'";
$expected = $FMT_INVALID_VALUE =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( -tempdir => 1 ) } qr/$expected/, $title;
test_test( $title );

$title    = "invalid value of '-tempfile'";
$expected = $FMT_INVALID_VALUE =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( -tempfile => 1 ) } qr/$expected/, $title;
test_test( $title );

$title    = 'unknown option with some value';
$expected = $FMT_UNKNOWN_OPTION =~ s/%s/.+/gr;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( unknown => 1 ) } qr/$expected/, $title;
test_test( $title );

$title    = 'unknown option without value';
$expected = $FMT_UNKNOWN_OPTION =~ s/%s/.+/r =~ s/%s//r;
readonly_off( $CLASS );
readonly_off( $METHOD );
readonly_off( $METHOD_REF );
readonly_off( $TEMP_DIR );
readonly_off( $TEMP_FILE );
readonly_off( $TEST_FILE );
test_out( "ok 1 - $title" );
throws_ok { $CLASS->$METHOD( 'unknown' ) } qr/$expected/, $title;
test_test( $title );
                                                            # For reasons I do not understand, yet,
unless ( exists( $ENV{ HARNESS_PERL_SWITCHES } ) ) {        # this fails during coverage evaluation
  $title    = "valid '-method', '-target' => undef (return value)";
  $expected = undef;
  readonly_off( $CLASS );
  readonly_off( $METHOD );
  readonly_off( $METHOD_REF );
  readonly_off( $TEMP_DIR );
  readonly_off( $TEMP_FILE );
  readonly_off( $TEST_FILE );
  test_out(
    join(
      "\n",
      sprintf( "# $FMT_SET_TO", '$CLASS',     $CLASS ),
      sprintf( "# $FMT_SET_TO", '$TEMP_DIR',  $TEMP_DIR ),
      sprintf( "# $FMT_SET_TO", '$TEMP_FILE', $TEMP_FILE ),
      sprintf( "# $FMT_SET_TO", '$TEST_FILE', path( __FILE__ )->absolute ),
      "ok 1 - $title",
    )
  );
  {
    my $mock_importer = mock 'Importer'  => ( override => [ import_into => sub {} ] );
    my $mock_test2    = mock 'Test2::V0' => ( override => [ import      => sub {} ] );
    is(
      dies {
        $CLASS->$METHOD( -color => { exported => undef, unexported => undef }, -method => 'dummy', -target => undef )
      }, $expected, $title
    );
  }
  test_test( $title );

  $title    = "undetectable '-method' (method name unassigned)";
  $expected = undef;
  test_out( "ok 1 - $title" );
  is( $METHOD, $expected, $title );
  test_test( $title );

  $title    = "omitted '-method', '-target' => undef (return value)";
  $expected = undef;
  readonly_off( $CLASS );
  readonly_off( $METHOD );
  readonly_off( $METHOD_REF );
  readonly_off( $TEMP_DIR );
  readonly_off( $TEMP_FILE );
  readonly_off( $TEST_FILE );
  test_out(
    join(
      "\n",
      sprintf( "# $FMT_SET_TO", colored( '$CLASS',     'green' ), $CLASS ),
      sprintf( "# $FMT_SET_TO", colored( '$TEMP_DIR',  'green' ), $TEMP_DIR ),
      sprintf( "# $FMT_SET_TO", colored( '$TEMP_FILE', 'green' ), $TEMP_FILE ),
      sprintf( "# $FMT_SET_TO", colored( '$TEST_FILE', 'green' ), path( __FILE__ )->absolute ),
      "ok 1 - $title",
    )
  );
  {
    my $mock_importer = mock 'Importer'  => ( override => [ import_into => sub {} ] );
    my $mock_test2    = mock 'Test2::V0' => ( override => [ import      => sub {} ] );
    is(
      dies {
        $CLASS->import( -color => { exported => 'green', unexported => 'red' }, -method => undef, -target => undef )
      }, $expected, $title
    );
  }
  test_test( $title );

  $title    = "omitted '-method', '-target' => undef (assigned method name)";
  $expected = undef;
  test_out( "ok 1 - $title" );
  is( $METHOD, $expected, $title );
  test_test( $title );

  $title = "test file absent (command line option '-e' simulated)";
  readonly_off( $CLASS );
  readonly_off( $METHOD );
  readonly_off( $METHOD_REF );
  readonly_off( $TEMP_DIR );
  readonly_off( $TEMP_FILE );
  readonly_off( $TEST_FILE );
  $CLASS = $METHOD = $METHOD_REF = $TEMP_DIR = $TEMP_FILE = $TEST_FILE = undef;
  no warnings qw( once );
  test_out( sprintf( '# ' . $Test::Expander::FMT_UNSET_VAR, colored( '$CLASS', 'red' ) ), "ok 1 - $title" );
  {
    my $mock_PathTiny = mock 'Path::Tiny'     => ( override => [ exists      => sub {} ] );
    my $mock_importer = mock 'Importer'       => ( override => [ import_into => sub {} ] );
    my $mock_test2    = mock 'Test2::V0'      => ( override => [ import      => sub {} ] );
    my $mock_this     = mock 'Test::Expander' => (
      override => [
        _export_rest_symbols => sub {},
        _mock_builtins       => sub {},
        _parse_options       => sub { {} },
        _set_env             => sub {},
      ]
    );
    is( Test::Expander->import( -target => undef ), undef, $title );
  }
  test_test( $title );
}
