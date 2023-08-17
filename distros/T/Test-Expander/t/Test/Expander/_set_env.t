## no critic (RequireLocalizedPunctuationVars)

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use File::chdir;

use Test::Expander -tempdir => {}, -srand => time;
use Test::Expander::Constants qw( $FMT_INVALID_ENV_ENTRY );

$METHOD     //= '_set_env';
$METHOD_REF //= $CLASS->can( $METHOD );
can_ok( $CLASS, $METHOD );

ok( -d $TEMP_DIR, "temporary directory '$TEMP_DIR' created" );

my $class_path = $CLASS =~ s{::}{/}gr;
my $test_path  = path( $TEMP_DIR )->child( 't' );
$test_path->child( $class_path )->mkpath;

{
  local $CWD   = $test_path->parent->stringify;              ## no critic (ProhibitLocalVars)

  my $test_file = path( 't' )->child( $class_path )->child( $METHOD . '.t' )->stringify;
  my $env_file  = path( 't' )->child( $class_path )->child( $METHOD . '.env' );

  is( Test2::Plugin::SRand->from, 'import arg', "random seed is supplied as 'time'" );

  ok( lives { $METHOD_REF->( $CLASS, $test_file ) }, 'no test file detected' );

  path( $test_file )->touch;

  subtest '1st env variable filled from a variable, 2nd one kept from %ENV, 3rd one ignored' => sub {
    our $var  = 'abc';
    my $name  = 'ABC';
    my $value = '$' . __PACKAGE__ . '::var';
    $env_file->spew( "$name = $value\nJust a comment line\nX\nY" );
    %ENV = ( XXX => 'yyy', X => 'A' );

    ok( lives { $METHOD_REF->( $CLASS, $test_file ) }, 'successfully executed' );
    my $expected = { $name => lc( $name ), X => 'A' };
    $expected->{ PWD } = $ENV{ PWD } if exists( $ENV{ PWD } );
    is( \%ENV, $expected,                             "'%ENV' has the expected content" );
  };

  subtest 'env variable filled by a self-implemented sub' => sub {
    my $name  = 'ABC';
    my $value = __PACKAGE__ . "::testEnv( lc( '$name' ) )";
    $env_file->spew( "$name = $value" );
    %ENV = ( XXX => 'yyy' );

    ok( lives { $METHOD_REF->( $CLASS, $test_file ) }, 'successfully executed' );
    my $expected = { $name => lc( $name ) };
    $expected->{ PWD } = $ENV{ PWD } if exists( $ENV{ PWD } );
    is( \%ENV, $expected,                             "'%ENV' has the expected content" );
  };

  subtest "env variable filled by a 'File::Temp::tempdir'" => sub {
    my $name  = 'ABC';
    my $value = 'File::Temp::tempdir';
    $env_file->spew( "$name = $value" );
    %ENV = ( XXX => 'yyy' );

    ok( lives { $METHOD_REF->( $CLASS, $test_file ) },      'successfully executed' );
    my %expected = ( $name => $value );
    $expected{ PWD } = $ENV{ PWD } if exists( $ENV{ PWD } );
    is( [ sort keys( %ENV ) ], [ sort keys( %expected ) ], "'%ENV' has the expected keys" );
    ok( -d $ENV{ $name },                                  'temporary directory exists' );
  };

  subtest 'env file does not exist' => sub {
    $env_file->remove;
    %ENV = ( XXX => 'yyy' );

    ok( lives { $METHOD_REF->( $CLASS, $test_file ) }, 'successfully executed' );
    my $expected = { XXX => 'yyy' };
    $expected->{ PWD } = $ENV{ PWD } if exists( $ENV{ PWD } );
    is( \%ENV, $expected,                             "'%ENV' remained unchanged" );
  };

  subtest 'directory structure does not correspond to class hierarchy' => sub {
    $env_file->remove;
    %ENV = ( XXX => 'yyy' );

    ok( lives { $METHOD_REF->( 'ABC::' . $CLASS, $test_file ) }, 'successfully executed' );
    my $expected = { XXX => 'yyy' };
    $expected->{ PWD } = $ENV{ PWD } if exists( $ENV{ PWD } );
    is( \%ENV, $expected,                                       "'%ENV' remained unchanged" );
  };

  subtest 'multiple levels of env files, cascade usage of their entries, overwrite entry' => sub {
    path( $env_file->parent->parent . '.env' )->spew( "C = '0'" );
    path( $env_file->parent         . '.env' )->spew( "A = '1'\nB = '2'\nD = \$ENV{ A } . \$ENV{ C }" );
    $env_file->spew( "C = '3'" );
    %ENV = ( XXX => 'yyy' );

    local $CWD = $TEMP_DIR;                                 ## no critic (ProhibitLocalVars)
    ok( lives { $METHOD_REF->( $CLASS, $test_file ) }, 'successfully executed' );
    my $expected = { A => '1', B => '2', C => '3', D => '10' };
    $expected->{ PWD } = $ENV{ PWD } if exists( $ENV{ PWD } );
    is( \%ENV, $expected,                             "'%ENV' has the expected content" );

    path( $env_file->parent->parent . '.env' )->remove;
    path( $env_file->parent         . '.env' )->remove;
  };

  subtest 'env file with invalid syntax' => sub {
    my $name  = 'ABC';
    my $value = 'abc->';
    $env_file->spew( "$name = $value" );

    my $expected = $FMT_INVALID_ENV_ENTRY =~ s/%d/0/r =~ s/%s/$env_file/r =~ s/%s/$name = $value/r =~ s/%s/.+/r;
    like( dies { $METHOD_REF->( $CLASS, $test_file ) }, qr/$expected/, 'expected exception raised' );
  };

  subtest 'env file with undefined values' => sub {
    my $name  = 'ABC';
    my $value = '$undefined';
    $env_file->spew( "$name = $value" );

    my $expected = $FMT_INVALID_ENV_ENTRY =~ s/%d/0/r =~ s/%s/$env_file/r =~ s/%s/$name = $value/r =~ s/%s/.+/r =~ s/(\$)/\\$1/r;
    like( dies { $METHOD_REF->( $CLASS, $test_file ) }, qr/$expected/m, 'expected exception raised' );
  };
}

done_testing();

sub testEnv { return $_[ 0 ] }                               ## no critic (RequireArgUnpacking)
