package Test::Files;

our $VERSION = '0.23';                                      ## no critic (RequireUseStrict, RequireUseWarnings)

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline portable recursion );

use Cwd           qw( abs_path );
use Data::Compare qw( Compare );
use Exporter      qw( import );
use Fcntl         qw( :mode );
use Path::Tiny    qw( path );
use Test::Builder;
use Text::Diff    qw( diff );

use Test::Files::Constants qw(
  $CONTAINER_OPTIONS $DIRECTORY_OPTIONS $EXPECTED_CONTENT
  $FMT_ABSENT $FMT_ABSENT_WITH_ERROR $FMT_DIFFERENT_SIZE $FMT_FAILED_TO_SEE $FMT_FILTER_ISNT_CODEREF
  $FMT_FIRST_FILE_ABSENT $FMT_INVALID_ARGUMENT $FMT_INVALID_DIR $FMT_INVALID_NAME_PATTER $FMT_INVALID_OPTIONS
  $FMT_SECOND_FILE_ABSENT $FMT_SUB_FAILED $FMT_UNDEF $FMT_UNEXPECTED $FILE_OPTIONS $UNKNOWN %DIFF_OPTIONS
);

## no critic (ProhibitAutomaticExportation)
our @EXPORT = qw(
  compare_dirs_filter_ok compare_dirs_ok
  compare_filter_ok compare_ok
  dir_contains_ok dir_only_contains_ok
  file_filter_ok file_ok find_ok
);

my $Test = Test::Builder->new;

sub compare_dirs_filter_ok {
  my ( $got_dir, $expected_dir, $filter, $name ) = @_;

  my $options  = { FILTER => $filter };
  my ( $diag ) = _validate_options( $options, $DIRECTORY_OPTIONS );

  return $diag ? _show_failure( $name, $diag ) : _compare_dirs( $got_dir, $expected_dir, $options, $name );
}

sub compare_dirs_ok {
  my ( $got_dir, $expected_dir, @rest ) = @_;

  my ( $diag, $options, $name ) = _validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );

  return $diag ? _show_failure( $name, $diag ) : _compare_dirs( $got_dir, $expected_dir, $options, $name );
}

sub compare_filter_ok {
  my ( $got_file, $expected_file, $filter, $name ) = @_;

  return _compare_ok( $got_file, $expected_file, { %$FILE_OPTIONS, FILTER => $filter }, $name );
}

sub compare_ok { return _compare_ok( @_ ) }

sub dir_contains_ok {
  my ( $dir, $file_list, @rest ) = @_;

  my ( $diag, $options, $name ) = _validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );

  return _show_failure( $name, $diag ) if $diag;

  ( $diag ) = _dir_contains_ok( $dir, $file_list, { %$options, EXISTENCE_ONLY => 1 }, $name );

  return _show_result( !@$diag, $name, @$diag );
}

sub dir_only_contains_ok {
  my ( $dir, $file_list, @rest ) = @_;

  my ( $diag, $options, $name ) = _validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );

  return _show_failure( $name, $diag ) if $diag;

  ( $diag ) = _dir_contains_ok( $dir, $file_list, { %$options, EXISTENCE_ONLY => 1, SYMMETRIC => 1 }, $name );

  return _show_result( !@$diag, $name, @$diag );
}

sub file_filter_ok {
  my ( $file, $expected_string, $filter, $name ) = @_;

  return _compare_ok( $file, \$expected_string, { %$FILE_OPTIONS, FILTER => $filter }, $name );
}

sub file_ok {
  my ( $file, $expected_string, @rest ) = @_;

  return _compare_ok( $file, \$expected_string, @rest );
}

sub find_ok {
  my ( $diag, $dir, $sub, $options, $name ) = _validate_args( 'CODE', @_ );
  return _show_failure( $name, $diag ) if $diag;

  $diag = [];
  my $match = sub { push( @$diag, $_ ) if $_->is_file && !$sub->( "$_" ) };
  path( $dir )->visit( $match, { recurse => $options->{ RECURSIVE } } );

  return _show_result( !@$diag, $name, sprintf( $FMT_SUB_FAILED, join( "', ", sort @$diag ) ) );
}

sub _compare_dirs {
  my ( $got_dir, $expected_dir, @rest ) = @_;

  my ( $diag, $options, $name ) = _validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );
  return _show_failure( $name, $diag )                                                     if $diag;
  return _show_failure( $name, sprintf( $FMT_UNDEF, '$got_dir',      _get_caller_sub() ) ) unless defined( $got_dir );
  return _show_failure( $name, sprintf( $FMT_UNDEF, '$expected_dir', _get_caller_sub() ) ) unless defined( $expected_dir );

  my $expected_file_list = [];
  path( $expected_dir )->visit(
    sub { push( @$expected_file_list, $_->relative( $expected_dir ) ) unless $_->is_dir },
    { recurse => $options->{ RECURSIVE } },
  );

  my $file_list;
  ( $diag, $file_list ) = _dir_contains_ok( $got_dir, $expected_file_list, $options, $name );
  $got_dir      = path( $got_dir );
  $expected_dir = path( $expected_dir );
  foreach my $file ( @$file_list ) {
    my $got_file      = $got_dir     ->child( $file );
    my $expected_file = $expected_dir->child( $file );
    my ( $error, $got_info, $expected_info ) = _get_two_files_info( $got_file, $expected_file, $options );
    push(
      @$diag,
      @$error ? @$error : @{ _compare_files( $got_info, $expected_info, $options, $got_file, $expected_file ) }
    );
  }

  return _show_result( !@$diag, $name, sort @$diag );
}

sub _compare_files {
  my ( $got_data, $expected_data, $options, $got_file, $expected_file ) = @_;

  if ( $options->{ EXISTENCE_ONLY } ) {
    return [ sprintf( $FMT_SECOND_FILE_ABSENT, $got_file, $expected_file ) ] unless $got_data;
    return [ sprintf( $FMT_FIRST_FILE_ABSENT,  $got_file, $expected_file ) ] unless $expected_data;
    return [];
  }

  if ( $options->{ SIZE_ONLY } ) {
    return $got_data == $expected_data
      ? [] : [ sprintf( $FMT_DIFFERENT_SIZE, $got_file, $expected_file, $got_data, $expected_data ) ];
  }

  my %diff_options = ( %DIFF_OPTIONS, map { $_ eq 'STYLE' ? ( $_ => $options->{ $_ } ) : () } keys( %$options ) );
  chomp(
    my $diff = diff(
      \$got_data, \$expected_data, { %diff_options, FILENAME_A => $got_file, FILENAME_B => $expected_file }
    )
  );
  return $diff eq '' ? [] : [ $diff ];
}

sub _compare_ok {
  my ( $got_file, $expected_file, @rest ) = @_;

  my ( $diag, $options, $name ) = _validate_trailing_args( \@rest, $FILE_OPTIONS );
  return _show_failure( $name, $diag )  if $diag;

  my ( $got, $expected );
  ( $diag, $got, $expected ) = _get_two_files_info(
    $got_file, $expected_file, $options, qw( $got_file $expected_file )
  );
  return _show_failure( $name, @$diag ) if @$diag;

  my $diff = _compare_files(
    $got, $expected, $options, $got_file, ref( $expected_file ) ? $EXPECTED_CONTENT : $expected_file
  );
  return _show_result( !@$diff, $name, @$diff );
}

# Verifies if the directory (1st parameter) contains all files from the file list (2nd parameter).
# If symmetric approach is required inside of option hash passed by reference (3rd parameter),
# also verifies if the directory does not contain any other files.
# If a certain file name pattern is required inside of option hash, files not matching this pattern are skipped.
# Subdirectories are not involved in the verification, but files located therein are considered
# if recursive appraoch is required inside of option hash.
# Special files like named pipes are involved in the verification only
# if the sole file existence is required inside of option hash,
# otherwise they are skipped and reported as error.
# Returns two references to:
# 1. Sorted array of detected errors.
# 2. Sorted array of files found in the directory and matching all requirements.
sub _dir_contains_ok {
  my ( $diag, $dir, $file_list, $options, $name ) = _validate_args( 'ARRAY', @_ );
  return [ $diag ] if $diag;

  my $name_pattern = $options->{ NAME_PATTERN };
     $name_pattern = qr/$name_pattern/;
  my ( $existence_only, $symmetric ) = @$options{ qw( EXISTENCE_ONLY SYMMETRIC ) };
  my $detected  = [];
  my %file_list = map { $_ => 1 } @$file_list;
  $diag         = [];
  my $matches   = sub {
    my ( $file ) = @_;

    my $file_stat = eval { $file->stat };
    return push( @$diag, sprintf( $FMT_ABSENT, $file ) ) unless $file_stat;
    return if S_ISDIR( $file_stat->mode );
    return push( @$diag, sprintf( $FMT_ABSENT, $file ) ) if $file_stat->rdev && !$existence_only;

    my $relative_name = $file->relative( $dir );
    if ( exists( $file_list{ $relative_name } ) ) {
      delete( $file_list{ $relative_name } );
      push( @$detected, $relative_name ) if $relative_name =~ $name_pattern;
      return;
    }

    return push( @$diag, sprintf( $FMT_UNEXPECTED, $file ) ) if $symmetric;

    return;
  };
  path( abs_path( $dir ) )->visit( $matches, { recurse => $options->{ RECURSIVE } } );
  push( @$diag, sprintf( $FMT_FAILED_TO_SEE, $dir->child( $_ ) ) ) foreach grep { /$name_pattern/ } keys( %file_list );

  return ( [ sort @$diag ], [ sort @$detected ] );
}

sub _get_caller_sub {                                       # Identify closest public caller subroutine
  my $caller_sub;
  for ( my $depth = 1; ; ++$depth ) {                       ## no critic (ProhibitCStyleForLoops)
    ( undef, undef, undef, $caller_sub ) = caller( $depth );
    last unless defined( $caller_sub ) && $caller_sub =~ /\b_/;
  }

  return defined( $caller_sub ) ? $caller_sub : $UNKNOWN;
}

sub _get_file_info {
  my ( $file, $options, $arg_name ) = @_;

  return ( sprintf( $FMT_UNDEF, $arg_name, _get_caller_sub() ), undef ) unless defined( $file );

  my $is_real_file = ref( $file ) ne 'SCALAR';
  my $file_stat;
  if ( $is_real_file ) {                                    # File name supplied
    $file      = path( $file );
    $file_stat = eval { $file->stat };                      # Error if file is absent or is not a plain one
    return ( sprintf( $FMT_ABSENT, $file ), undef )
      if !$file_stat || S_ISDIR( $file_stat->mode ) || $file_stat->rdev && !$options->{ EXISTENCE_ONLY };
  }

  return ( undef, 1 )                                                   if $options->{ EXISTENCE_ONLY };
  return ( undef, $is_real_file ? $file_stat->size : length( $$file ) ) if $options->{ SIZE_ONLY };

  local $.    = 0;
  my $filter  = $options->{ FILTER };
  my $content = $is_real_file
    ? eval {
        $filter
          ? join( '', map { ++$.; my $filtered = $filter->( $_ ); defined( $filtered ) ? $filtered : () } $file->lines )
          : $file->slurp
      }
    : $$file;
  my $diag = $@ ? sprintf( $FMT_ABSENT_WITH_ERROR, $file, $@ ) : undef;

  return ( $diag, $content );
}

sub _get_two_files_info {
  my ( $got_file, $expected_file, $options, $got_name, $expected_name ) = @_;

  my ( $got_diag,      $got_data  )     = _get_file_info( $got_file,      $options, $got_name );
  my ( $expected_diag, $expected_data ) = _get_file_info( $expected_file, $options, $expected_name );

  return (
    [ defined( $got_diag ) ? $got_diag : (), defined( $expected_diag ) ? $expected_diag : () ],
    $got_data,
    $expected_data
  );
}

sub _show_failure {
  my ( $name, @message ) = @_;

  $Test->ok( 0, $name );
  $Test->diag( join( "\n", @message, '' ) );

  return;
}

sub _show_result {
  my ( $success, $name, @message ) = @_;

  return $success ? $Test->ok( 1, $name ) : _show_failure( $name, @message );
}

sub _validate_args {
  my ( $expected_type, $dir, $file_list_or_sub, @rest ) = @_;

  my ( $diag, $options, $name ) = _validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );
  return $diag if $diag;

  return sprintf( $FMT_UNDEF, '$dir', _get_caller_sub() ) unless defined( $dir );

  $dir = path( $dir );
  return sprintf( $FMT_INVALID_DIR, $dir ) unless $dir->is_dir;

  return sprintf(
    $FMT_INVALID_ARGUMENT, _get_caller_sub(), ( $expected_type eq 'ARRAY' ? 'array' : 'code' ) . ' reference', '2nd'
  ) if ref( $file_list_or_sub ) ne $expected_type;

  return ( undef, $dir, $file_list_or_sub, $options, $name );
}

sub _validate_options {
  my ( $options, $default ) = @_;

  my @invalid_options = grep { !exists( $default->{ $_ } ) } keys( %$options );
  return sprintf( $FMT_INVALID_OPTIONS, join( "', '", @invalid_options ) ) if @invalid_options;

  if ( defined( $options->{ FILTER } ) ) {
    return sprintf( $FMT_FILTER_ISNT_CODEREF, _get_caller_sub() ) if ref( $options->{ FILTER } ) ne 'CODE';
  }
  else {
    $options->{ FILTER } = $default->{ FILTER };
  }

  if ( exists( $default->{ NAME_PATTERN } ) ) {
    if ( defined( $options->{ NAME_PATTERN } ) ) {
      eval { qr/$options->{ NAME_PATTERN }/ };
      my $error = $@;
      return sprintf( $FMT_INVALID_NAME_PATTER, $options->{ NAME_PATTERN }, _get_caller_sub(), $error ) if $error;
    }
    else {
      $options->{ NAME_PATTERN } = $default->{ NAME_PATTERN };
    }
  }

  return ( undef, %$default, %$options );
}

sub _validate_trailing_args {
  my ( $args, $default ) = @_;

  return ( undef, $default ) unless @$args;                 # 1st trailing arg omitted: use default options, no title

  my ( $first_arg, $second_arg ) = @$args;
  my $first_arg_type = ref( $first_arg );

  return ( undef, $default, $first_arg )                    # Scalar: use default options and 3rd param as title
    unless $first_arg_type;

  if  ( $first_arg_type eq 'HASH' ) {                       # Hash reference: forward both options and title
    my ( $diag, %options ) = _validate_options( $first_arg, $default );
    return $diag ? ( $diag ) : ( undef, { %$default, %options }, $second_arg )
  }

  return ( undef, { %$default, FILTER => $first_arg }, $second_arg )
    if $first_arg_type eq 'CODE';                           # Code reference: forward filter as option and title

                                                            # Invalid type
  return sprintf( $FMT_INVALID_ARGUMENT, _get_caller_sub(), 'hash reference / code reference / string', '3rd' );
}

1;
