## no critic ( ProhibitStringyEval ProhibitSubroutinePrototypes RequireLocalizedPunctuationVars)
package Test::Expander;

# The versioning is conform with https://semver.org
our $VERSION = '2.5.1';                                     ## no critic (RequireUseStrict, RequireUseWarnings)

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Const::Fast;
use File::chdir;
use File::Temp          qw( tempdir tempfile );
use Getopt::Long        qw( GetOptions :config posix_default );
use Importer;
use Path::Tiny          qw( cwd path );
use Scalar::Readonly    qw( readonly_on );
use Term::ANSIColor     qw( color colored );
use Test::Builder;
use Test2::API          qw( context );
use Test2::API::Context qw();
use Test2::Tools::Basic;
use Test2::Tools::Explain;
use Test2::Tools::Subtest;

use Test::Expander::Constants qw(
  $DIE $FALSE
  $FMT_INVALID_COLOR $FMT_INVALID_DIRECTORY $FMT_INVALID_ENV_ENTRY $FMT_INVALID_VALUE $FMT_INVALID_SUBTEST_NUMBER
  $FMT_KEEP_ENV_VAR $FMT_NEW_FAILED $FMT_NEW_SUCCEEDED $FMT_REPLACEMENT $FMT_REQUIRE_DESCRIPTION
  $FMT_REQUIRE_IMPLEMENTATION $FMT_SEARCH_PATTERN $FMT_SET_ENV_VAR $FMT_SET_TO $FMT_SKIP_ENV_VAR $FMT_UNSET_VAR
  $FMT_UNKNOWN_OPTION $FMT_USE_DESCRIPTION $FMT_USE_IMPLEMENTATION $MSG_BAIL_OUT $MSG_ERROR_WAS $MSG_UNEXPECTED_EXCEPTION
  $NOTE
  $REGEX_ANY_EXTENSION $REGEX_CLASS_HIERARCHY_LEVEL $REGEX_TOP_DIR_IN_PATH $REGEX_VERSION_NUMBER
  $TRUE
  %COLORS %MOST_CONSTANTS_TO_EXPORT %REST_CONSTANTS_TO_EXPORT
);

my $ok_orig = \&Test2::API::Context::ok;
my ( @subtest_names, @subtest_numbers );
my %colors = %COLORS;

sub _subtest_selection {
  my $error;
  GetOptions(
    'subtest_name|subtest=s' => sub {
      ( undef, my $opt_value ) = @_;
      push( @subtest_names, eval { qr/$opt_value/ } ? $opt_value : "\Q$opt_value\E" );
    },
    'subtest_number=s' => sub {
      ( undef, my $opt_value ) = @_;
      $error = sprintf( $FMT_INVALID_SUBTEST_NUMBER, $opt_value ) if $opt_value !~ m{^ \d+ (?: / \d+ )* $}x;
      push( @subtest_numbers, $opt_value );
    },
  );
  die( $error) if $error;

  my $subtest_buffered_orig = \&Test2::Tools::Subtest::subtest_buffered;
  my $subtest_streamed_orig = \&Test2::Tools::Subtest::subtest_streamed;
  no warnings qw( redefine );
  *Test2::Tools::Subtest::subtest_buffered = sub { _subtest_conditional( $subtest_buffered_orig, @_ ) };
  *Test2::Tools::Subtest::subtest_streamed = sub { _subtest_conditional( $subtest_streamed_orig, @_ ) };

  return;
}

BEGIN { _subtest_selection() }

use Test2::V0 qw();

readonly_on( $VERSION );

our ( $CLASS, $METHOD, $METHOD_REF, $TEMP_DIR, $TEMP_FILE, $TEST_FILE );
our @EXPORT = (
  @{ Const::Fast::EXPORT },
  @{ Test2::Tools::Explain::EXPORT },
  @{ Test2::V0::EXPORT },
  qw( tempdir tempfile ),
  qw( cwd path ),
  qw( BAIL_OUT bail_on_failure dies_ok is_deeply lives_ok new_ok require_ok restore_failure_handler throws_ok use_ok ),
);

{
  no warnings qw( once );
  *BAIL_OUT = \&bail_out;                                   # Explicit "sub BAIL_OUT" would be untestable
}

sub bail_on_failure {
  _set_failure_handler(
    sub {
      # uncoverable subroutine
      bail_out( $MSG_BAIL_OUT )                             # uncoverable statement
    }
  );

  return;
}

sub dies_ok ( &;$ ) {
  my ( $coderef, $description ) = @_;

  eval { $coderef->() };

  return ok( $@, $description );
}

sub import {
  my ( $class, @exports ) = @_;

  my $frame_index = 0;
  my $test_file;
  while( my @current_frame = caller( $frame_index++ ) ) {
    $test_file = path( $current_frame[ 1 ] ) =~ s{^/}{}r;
  }
  my $options = _parse_options( \@exports, $test_file );

  _export_most_symbols( $test_file );
  _set_env( $options->{ -target }, $test_file );
  _mock_builtins( $options ) if defined( $CLASS ) && exists( $options->{ -builtins } );

  Test2::V0->import( %$options );

  _export_rest_symbols();
  Importer->import_into( $class, scalar( caller ), () );

  return;
}

sub is_deeply ( $$;$@ ) {
  my ( $got, $expected, $title ) = @_;

  return is( $got, $expected, $title );
}

sub lives_ok ( &;$ ) {
  my ( $coderef, $description ) = @_;

  eval { $coderef->() };
  diag( $MSG_UNEXPECTED_EXCEPTION . $@ ) if $@;

  return ok( !$@, $description );
}

sub new_ok {
  my ( $class, $args ) = @_;

  $args ||= [];
  my $obj = eval { $class->new( @$args ) };
  ok( !$@, _new_test_message( $class ) );

  return $obj;
}

sub require_ok {
  my ( $module ) = @_;

  my $package        = caller;
  my $require_result = eval( sprintf( $FMT_REQUIRE_IMPLEMENTATION, $package, $module ) );
  ok( $require_result, sprintf( $FMT_REQUIRE_DESCRIPTION, $module, _error() ) );

  return $require_result;
}

sub restore_failure_handler {
  no warnings qw( redefine );
  *Test2::API::Context::ok = $ok_orig;

  return;
}

sub throws_ok ( &$;$ ) {
  my ( $coderef, $expecting, $description ) = @_;

  eval { $coderef->() };
  my $exception     = $@;
  my $expected_type = ref( $expecting );

  return $expected_type eq 'Regexp' ? like  ( $exception,   $expecting,   $description )
                                    : isa_ok( $exception, [ $expecting ], $description );
}

sub use_ok ( $;@ ) {
  my ( $module, @imports ) = @_;

  my ( $package, $filename, $line ) = caller( 0 );
  $filename =~ y/\n\r/_/;                                   # taken over from Test::More

  my $require_result = eval( sprintf( $FMT_USE_IMPLEMENTATION, $package, $module, _use_imports( \@imports ) ) );
  ok(
    $require_result,
    sprintf(
      $FMT_USE_DESCRIPTION, $module, _error( $FMT_SEARCH_PATTERN, sprintf( $FMT_REPLACEMENT, $filename, $line ) )
    )
  );

  return $require_result;
}

sub _colorize {
  my ( $value, $export_type ) = @_;

  return defined( $colors{ $export_type } ) ? colored( $value, $colors{ $export_type } ) : $value;
}

sub _determine_testee {
  my ( $options, $test_file ) = @_;

  if ( $options->{ -lib } ) {
    foreach my $directory ( @{ $options->{ -lib } } ) {
      $DIE->( $FMT_INVALID_DIRECTORY, $directory, 'invalid type' ) if ref( $directory );
      my $inc_entry = eval( $directory );
      $DIE->( $FMT_INVALID_DIRECTORY, $directory, $@ ) if $@;
      unshift( @INC, $inc_entry );
    }
    delete( $options->{ -lib } );
  }

  if ( exists( $options->{ -method } ) ) {
    delete( $options->{ -method } );
  }
  else {
    $METHOD = path( $test_file )->basename( $REGEX_ANY_EXTENSION );
  }

  unless ( exists( $options->{ -target } ) ) {              # Try to determine class / module autmatically
    my ( $test_root ) = $test_file =~ $REGEX_TOP_DIR_IN_PATH;
    my $testee        = path( $test_file )->relative( $test_root )->parent;
    $options->{ -target } = "$testee" =~ s{/}{::}gr if grep { path( $_ )->child( $testee . '.pm' )->is_file } @INC;
  }
  if ( defined( $options->{ -target } ) ) {
    $CLASS = $options->{ -target };
  }
  else {
    delete( $options->{ -target } );
  }

  return $options;
}

sub _error {
  my ( $search_string, $replacement_string ) = @_;

  return '' if $@ eq '';

  my $error = $MSG_ERROR_WAS . $@ =~ s/\n$//mr;
  $error =~ s/$search_string/$replacement_string/m if defined( $search_string );

  return $error;
}

sub _export_most_symbols {
  my ( $test_file ) = @_;

  $TEST_FILE = path( $test_file )->absolute->stringify if path( $test_file )->exists;

  return _export_symbols( %MOST_CONSTANTS_TO_EXPORT );
}

sub _export_rest_symbols {
                                                            # Further export if class and method are known
  return _export_symbols( %REST_CONSTANTS_TO_EXPORT ) if $CLASS && $METHOD && ( $METHOD_REF = $CLASS->can( $METHOD ) );

  $METHOD = undef;

  return;
}

sub _export_symbols {
  my %constants = @_;

  foreach my $name ( sort keys( %constants ) ) {            # Export defined constants
    no strict qw( refs );
    my $value = eval( "${ \$name }" );
    if ( defined( $value ) ) {
      readonly_on( ${ __PACKAGE__ . '::' . $name =~ s/^.//r } );
      push( @EXPORT, $name );
      $NOTE->( $FMT_SET_TO, _colorize( $name, 'exported' ), $constants{ $name }->( $value, $CLASS ) );
    }
    elsif ( $name =~ /^ \$ (?: CLASS | METHOD | METHOD_REF )$/x ) {
      $NOTE->( $FMT_UNSET_VAR, _colorize( $name, 'unexported' ) );
    }
  }

  return;
}

sub _mock_builtins {
  my ( $options ) = @_;

  while ( my ( $sub_name, $sub_ref ) = each( %{ $options->{ -builtins } } ) ) {
    my $sub_full_name = $CLASS . '::' . $sub_name;
    no strict qw( refs );
    *${ sub_full_name } = $sub_ref;
  }
  delete( $options->{ -builtins } );

  return;
}

sub _new_test_message {
  my ( $class ) = @_;

  return $@ ? sprintf( $FMT_NEW_FAILED, $class, _error() ) : sprintf( $FMT_NEW_SUCCEEDED, $class, $class );
}

sub _parse_options {                                        ## no critic (ProhibitExcessComplexity)
  my ( $exports, $test_file ) = @_;

  my $options = {};
  while ( my $option_name = shift( @$exports ) ) {
    $DIE->( $FMT_UNKNOWN_OPTION, $option_name, shift( @$exports ) // '' ) if $option_name !~ /^-\w/;

    my $option_value = shift( @$exports );
    if ( $option_name eq '-bail' ) {                        ## no critic (ProhibitCascadingIfElse)
      _set_failure_handler(
        sub {
          # uncoverable subroutine
          bail_out( $MSG_BAIL_OUT )                         # uncoverable statement
        }
      );
    }
    elsif ( $option_name eq '-builtins' ) {
      $DIE->( $FMT_INVALID_VALUE, $option_name, $option_value ) if ref( $option_value ) ne 'HASH';
      while ( my ( $sub_name, $sub_ref ) = each( %$option_value ) ) {
        $DIE->( $FMT_INVALID_VALUE, $option_name . "->{ $sub_name }", $sub_ref ) if ref( $sub_ref ) ne 'CODE';
      }
      $options->{ $option_name } = $option_value;
    }
    elsif ( $option_name eq '-color' ) {
      while ( my ( $color_name, $color_value ) = each( %colors ) ) {
        if ( exists( $option_value->{ $color_name } ) ) {
          my $requested_color = $option_value->{ $color_name };
          $DIE->( $FMT_INVALID_COLOR, $requested_color, $color_name )
            if defined( $requested_color ) && !defined( color( $requested_color ) );
          $colors{ $color_name } = $requested_color;
        }
      }
      foreach my $color_name ( keys( %$option_value ) ) {
        $DIE->( $FMT_UNKNOWN_OPTION, $option_name, $color_name ) unless exists( $colors{ $color_name } );
      }
    }
    elsif ( $option_name eq '-lib' ) {
      $DIE->( $FMT_INVALID_VALUE, $option_name, $option_value ) if ref( $option_value ) ne 'ARRAY';
      $options->{ $option_name } = $option_value;
    }
    elsif ( $option_name eq '-method' ) {
      $DIE->( $FMT_INVALID_VALUE, $option_name, $option_value ) if ref( $option_value );
      $METHOD = $options->{ $option_name } = $option_value;
    }
    elsif ( $option_name eq '-target' ) {
      $options->{ $option_name } = $option_value;
    }
    elsif ( $option_name eq '-tempdir' ) {
      $DIE->( $FMT_INVALID_VALUE, $option_name, $option_value ) if ref( $option_value ) ne 'HASH';
      $TEMP_DIR = tempdir( CLEANUP => 1, %$option_value );
    }
    elsif ( $option_name eq '-tempfile' ) {
      $DIE->( $FMT_INVALID_VALUE, $option_name, $option_value ) if ref( $option_value ) ne 'HASH';
      my $file_handle;
      ( $file_handle, $TEMP_FILE ) = tempfile( UNLINK => 1, %$option_value );
    }
    else {
      $options->{ $option_name } = $option_value;
    }
  }

  return _determine_testee( $options, $test_file );
}

sub _read_env_file {
  my ( $env_file ) = @_;

  my @lines = path( $env_file )->lines( { chomp => 1 } );
  my %env;
  while ( my ( $index, $line ) = each( @lines ) ) {
                                                            ## no critic (ProhibitUnusedCapture)
    next unless $line =~ /^ (?<name> \w+) \s* (?: = \s* (?<value> \S .*) | $ )/x;
    my ( $name, $value ) = @+{ qw( name value ) };
    if ( exists( $+{ value } ) ) {
      my $stricture = q{
        use strict;
        use warnings
          FATAL    => qw( all ),
          NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );
      };
      $value = eval {
        eval( $stricture . '$value' );
        die( $@ ) if $@;                                    # uncoverable branch true
        $value = eval( $stricture . $value );
        die( $@ ) if $@;
        $value;
      };
      $DIE->( $FMT_INVALID_ENV_ENTRY, $index, $env_file, $line, $@ =~ s/\n//gr =~ s/ at \(eval .+//ir ) if $@;
      if ( defined( $value ) ) {
        $NOTE->( $FMT_SET_ENV_VAR, _colorize( $name, 'exported' ), $value, $env_file );
        $ENV{ $name } = $env{ $name } = $value;
      }
      else {
        $NOTE->( $FMT_SKIP_ENV_VAR, _colorize( $name, 'unexported' ), $env_file );
      }
    }
    elsif ( exists( $ENV{ $+{ name } } ) ) {
      $env{ $name } = $ENV{ $name };
      $NOTE->( $FMT_KEEP_ENV_VAR, _colorize( $name, 'exported' ), $ENV{ $name }, $env_file );
    }
  }

  return \%env;
}

sub _set_env {
  my ( $class, $test_file ) = @_;

  return unless path( $test_file )->exists;

  my $env_found = $FALSE;
  my $new_env   = {};
  {
    local $CWD = $test_file =~ s{/.*}{}r;                   ## no critic (ProhibitLocalVars)
    ( $env_found, $new_env ) = _set_env_hierarchically( $class, $env_found, $new_env );
  }

  my $env_file = $test_file =~ s/$REGEX_ANY_EXTENSION/.env/r;

  if ( path( $env_file )->is_file ) {
    $env_found                        = $TRUE unless $env_found;
    my $method_env                    = _read_env_file( $env_file );
    @$new_env{ keys( %$method_env ) } = values( %$method_env );
  }

  %ENV = %$new_env if $env_found;

  return;
}

sub _set_env_hierarchically {
  my ( $class, $env_found, $new_env ) = @_;

  return ( $env_found, $new_env ) unless $class;

  my $class_top_level;
  ( $class_top_level, $class ) = $class =~ $REGEX_CLASS_HIERARCHY_LEVEL;

  return ( $FALSE, {} ) unless path( $class_top_level )->is_dir;

  my $env_file = $class_top_level . '.env';
  if ( path( $env_file )->is_file ) {
    $env_found = $TRUE unless $env_found;
    $new_env   = { %$new_env, %{ _read_env_file( $env_file ) } };
  }

  local $CWD = $class_top_level;                            ## no critic (ProhibitLocalVars)

  return _set_env_hierarchically( $class, $env_found, $new_env );
}

sub _set_failure_handler {
  my $action = shift;
  no warnings qw( redefine );
  *Test2::API::Context::ok = sub {
    my ( undef, $pass ) = @_;
    my $result = $ok_orig->( @_ );
    $action->() unless $pass;                               # uncoverable branch true

    return $result;
  };

  return;
}

sub _subtest_conditional {
  my ( $orig_subtest, $name, @rest ) = @_;

  my $ctx    = context();
  my $number = join( '/', map { $_->count } @{ $ctx->stack } );
  if (
    !@subtest_names && !@subtest_numbers      ||
    ( grep { $name =~ /$_/ } @subtest_names ) ||
    ( grep { /^$number/    } @subtest_numbers )
  ) {
    $orig_subtest->( $name, @rest );
    $ctx->release;
  }
  else {
    $ctx->skip( 'forced by ' . __PACKAGE__ );
    $ctx->release;
  }

  return;
}

sub _use_imports {
  my ( $imports ) = @_;

  return @$imports == 1 && $imports->[ 0 ] =~ $REGEX_VERSION_NUMBER ? ' ' . $imports->[ 0 ] : '';
}

1;
