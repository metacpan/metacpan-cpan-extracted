package Test::Files;

our $VERSION = '0.26';                                      ## no critic (RequireUseStrict, RequireUseWarnings)

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline portable recursion );

use Class::XSAccessor accessors => [ qw( base diag expected got name options ) ], chained => 1;
use Cwd                   qw( abs_path );
use Data::Compare         qw( Compare );
use Exporter              qw( import );
use Fcntl                 qw( :mode );
use File::chdir;
use Path::Tiny            qw( path );
use Test::Builder;
use Test2::Tools::Compare qw( is );
use Text::Diff            qw( diff );

use Test::Files::Constants qw(
  $ARCHIVE_OPTIONS $DIRECTORY_OPTIONS $EXPECTED_CONTENT
  $FMT_ABSENT $FMT_ABSENT_WITH_ERROR $FMT_CANNOT_CREATE_DIR $FMT_CANNOT_EXTRACT $FMT_CANNOT_GET_METADATA
  $FMT_DIFFERENT_SIZE $FMT_FAILED_TO_SEE $FMT_FILTER_ISNT_CODEREF $FMT_FIRST_FILE_ABSENT $FMT_INVALID_ARGUMENT
  $FMT_INVALID_DIR $FMT_INVALID_NAME_PATTER $FMT_INVALID_OPTIONS $FMT_SECOND_FILE_ABSENT $FMT_SUB_FAILED $FMT_UNDEF
  $FMT_UNEXPECTED $FILE_OPTIONS $UNKNOWN
  %DIFF_OPTIONS
);

## no critic (ProhibitAutomaticExportation)
our @EXPORT = qw(
  compare_archives_ok
  compare_dirs_filter_ok compare_dirs_ok
  compare_filter_ok compare_ok
  dir_contains_ok dir_only_contains_ok
  file_filter_ok file_ok
  find_ok
);

my $Test = Test::Builder->new;

sub compare_archives_ok {
  my ( $got_archive, $expected_archive, @rest ) = @_;

  my $self = __PACKAGE__->_init->got( $got_archive )->expected( $expected_archive )
    ->_validate_trailing_args( \@rest, $ARCHIVE_OPTIONS );

  return $self->_show_failure if @{ $self->diag } || @{ $self->_compare_metadata->diag };

  $self->_extract->diag;
  return 0 unless defined( $self->diag );                   # Special handling of metadata difference
  return $self->_show_failure if @{ $self->diag };

  map { delete( $self->options->{ $_ } ) unless exists( $DIRECTORY_OPTIONS->{ $_ } ) } keys( %{ $self->options } );
  return $self->_compare_dirs;
}

sub compare_dirs_filter_ok {
  my ( $got_dir, $expected_dir, $filter, $name ) = @_;

  my $self = __PACKAGE__->_init->got( $got_dir )->expected( $expected_dir )->name( $name )->options( { FILTER => $filter } )
    ->_validate_options( $DIRECTORY_OPTIONS );

  return @{ $self->diag } ? $self->_show_failure : $self->_compare_dirs;
}

sub compare_dirs_ok {
  my ( $got_dir, $expected_dir, @rest ) = @_;

  my $self = __PACKAGE__->_init->got( $got_dir )->expected( $expected_dir )
    ->_validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );

  return @{ $self->diag } ? $self->_show_failure : $self->_compare_dirs;
}

sub compare_filter_ok {
  my ( $got_file, $expected_file, $filter, $name ) = @_;

  ## no critic (ProtectPrivateSubs)
  return __PACKAGE__->_init->_compare_ok( $got_file, $expected_file, { FILTER => $filter }, $name );
}

## no critic (ProtectPrivateSubs)
sub compare_ok { return __PACKAGE__->_init->_compare_ok( @_ ) }

sub dir_contains_ok {
  my ( $dir, $file_list, @rest ) = @_;

  ## no critic (ProtectPrivateSubs)
  my $self = __PACKAGE__->_init->_validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );

  return $self->_show_failure if @{ $self->diag };

  $self->_dir_contains_ok( $dir, $file_list, { %{ $self->options }, EXISTENCE_ONLY => 1 }, $self->name );

  return $self->_show_result( @{ $self->diag } );
}

sub dir_only_contains_ok {
  my ( $dir, $file_list, @rest ) = @_;

  ## no critic (ProtectPrivateSubs)
  my $self = __PACKAGE__->_init->_validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );

  return $self->_show_failure if @{ $self->diag };

  $self->_dir_contains_ok( $dir, $file_list, { %{ $self->options }, EXISTENCE_ONLY => 1, SYMMETRIC => 1 }, $self->name );

  return $self->_show_result( @{ $self->diag } );
}

sub file_filter_ok {
  my ( $file, $expected_string, $filter, $name ) = @_;

  ## no critic (ProtectPrivateSubs)
  return __PACKAGE__->_init->_compare_ok( $file, \$expected_string, { %$FILE_OPTIONS, FILTER => $filter }, $name );
}

sub file_ok {
  my ( $file, $expected_string, @rest ) = @_;

  ## no critic (ProtectPrivateSubs)
  return __PACKAGE__->_init->_compare_ok( $file, \$expected_string, @rest );
}

sub find_ok {
  my ( $dir, @rest ) = @_;

  my $self    = __PACKAGE__->_init->got( path( $dir ) );
  my ( $sub ) = $self->_validate_args( 'CODE', @_ );
  return $self->_show_failure if @{ $self->diag };

  my @diag;
  my $match = sub { push( @diag, $_ ) if $_->is_file && !$sub->( "$_" ) };
  $self->got->visit( $match, { recurse => $self->options->{ RECURSIVE } } );

  return $self->_show_result( sprintf( $FMT_SUB_FAILED, join( "', ", sort @{ $self->diag } ) ) );
}

sub _compare_dirs {
  my ( $self ) = @_;

  my $expected_dir = $self->expected;
  return $self->_show_failure( sprintf( $FMT_UNDEF, '$expected_dir', _get_caller_sub() ) ) unless defined( $expected_dir );

  my $got_dir = $self->got;
  return $self->_show_failure( sprintf( $FMT_UNDEF, '$got_dir',      _get_caller_sub() ) ) unless defined( $got_dir );

  my $options = $self->options;
  my $expected_file_list = [];
  path( $expected_dir )->visit(
    sub { push( @$expected_file_list, $_->relative( $expected_dir ) ) unless $_->is_dir },
    { recurse => $options->{ RECURSIVE } },
  );

  my $file_list = $self->_dir_contains_ok( $got_dir, $expected_file_list, $options, $self->name );
  my @diag      = @{ $self->diag };
  $got_dir      = path( $got_dir );
  $expected_dir = path( $expected_dir );
  foreach my $file ( @$file_list ) {
    $self->diag( [] );
    my $got_file      = $got_dir     ->child( $file );
    my $expected_file = $expected_dir->child( $file );
    my ( $got_info, $expected_info ) = $self->_get_two_files_info( $got_file, $expected_file );
    $self->_compare_files( $got_info, $expected_info, $self->_relative( $got_file ), $self->_relative( $expected_file ) )
      unless @{ $self->diag };
    push( @diag, @{ $self->diag } );
  }
  $self->diag( \@diag );

  return $self->_show_result( sort @{ $self->diag } );
}

sub _compare_files {
  my ( $self, $got_data, $expected_data, $got_file, $expected_file ) = @_;

  my $options = $self->options;
  if ( $options->{ EXISTENCE_ONLY } ) {
    $self->diag( [ sprintf( $got_data ? $FMT_SECOND_FILE_ABSENT : $FMT_FIRST_FILE_ABSENT, $got_file, $expected_file ) ] )
      unless $got_data && $expected_data;
    return $self;
  }

  if ( $options->{ SIZE_ONLY } ) {
    $self->diag( [ sprintf( $FMT_DIFFERENT_SIZE, $got_file, $expected_file, $got_data, $expected_data ) ] )
      unless $got_data == $expected_data;
    return $self;
  }

  my %diff_options = ( %DIFF_OPTIONS, map { $_ eq 'STYLE' ? ( $_ => $options->{ $_ } ) : () } keys( %$options ) );
  chomp(
    my $diff = diff(
      \$got_data, \$expected_data, { %diff_options, FILENAME_A => $got_file, FILENAME_B => $expected_file }
    )
  );
  $self->diag( [ $diff ] ) if $diff ne '';

  return $self;
}

sub _compare_metadata {
  my ( $self ) = @_;

  my $got_metadata = eval { $self->options->{ META_DATA }->( $self->got ) };
  return $self->diag( [ sprintf( $FMT_CANNOT_GET_METADATA, $self->got, $@ ) ] ) if $@;

  my $expected_metadata = eval { $self->options->{ META_DATA }->( $self->expected ) };
  return $self->diag( [ sprintf( $FMT_CANNOT_GET_METADATA, $self->expected, $@ ) ] ) if $@;

  return $self if Compare( $got_metadata, $expected_metadata );

  is( $got_metadata, $expected_metadata, $self->name );
  return $self->diag( undef );
}

sub _compare_ok {
  my ( $self, $got_file, $expected_file, @rest ) = @_;

  $self->_validate_trailing_args( \@rest, $FILE_OPTIONS );
  return $self->_show_failure if @{ $self->diag };

  my ( $got, $expected ) = $self->_get_two_files_info( $got_file, $expected_file, qw( $got_file $expected_file ) );
  return $self->_show_failure if @{ $self->diag };

  return $self->_compare_files( $got, $expected, $got_file, ref( $expected_file ) ? $EXPECTED_CONTENT : $expected_file )
              ->_show_result( @{ $self->diag } );
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
# Returns reference to sorted array of files found in the directory and matching all requirements.
sub _dir_contains_ok {
  my $self = shift;

  my $file_list = $self->_validate_args( 'ARRAY', @_ );
  return [] if @{ $self->diag };

  my $options      = $self->options;
  my $name_pattern = $options->{ NAME_PATTERN };
     $name_pattern = qr/$name_pattern/;
  my ( $existence_only, $symmetric ) = @$options{ qw( EXISTENCE_ONLY SYMMETRIC ) };
  my $detected  = [];
  my $diag      = [];
  my $dir       = $self->got;
  my %file_list = map { $_ => 1 } @$file_list;
  my $matches   = sub {
    my ( $file ) = @_;

    my $file_stat = eval { $file->stat };
    return push( @$diag, sprintf( $FMT_ABSENT, $self->_relative( $file ) ) ) unless $file_stat;
    return if S_ISDIR( $file_stat->mode );
    return push( @$diag, sprintf( $FMT_ABSENT, $self->_relative( $file ) ) ) if $file_stat->rdev && !$existence_only;

    my $relative_name = $file->relative( $dir );
    if ( exists( $file_list{ $relative_name } ) ) {
      delete( $file_list{ $relative_name } );
      push( @$detected, $relative_name ) if $relative_name =~ $name_pattern;
      return;
    }

    return push( @$diag, sprintf( $FMT_UNEXPECTED, $self->_relative( $file ) ) ) if $symmetric;

    return;
  };
  path( abs_path( $self->got ) )->visit( $matches, { recurse => $options->{ RECURSIVE } } );
  push( @$diag, sprintf( $FMT_FAILED_TO_SEE, $self->_relative( $dir->child( $_ ) ) ) )
    foreach grep { /$name_pattern/ } keys( %file_list );
  $self->diag( [ sort @$diag ] );

  return [ sort @$detected ];
}

sub _extract {
  my ( $self ) = @_;

  $self->base( Path::Tiny->tempdir );
  foreach my $archive ( $self->got, $self->expected ) {
    my $base       = $self->base;
    my $targetPath = eval { $base->child( $archive )->mkdir };
    return $self->diag( [ sprintf( $FMT_CANNOT_CREATE_DIR, $base->child( $archive ), $@ ) ] ) if $@;

    local $CWD = $targetPath;                               ## no critic (ProhibitLocalVars)
    eval { $self->options->{ EXTRACT }->( $archive ) };
    return $self->diag( [ sprintf( $FMT_CANNOT_EXTRACT, $archive, $base->child( $archive ), $@ ) ] ) if $@;
  }

  $self->$_( $self->base->child( $self->$_ ) ) foreach qw( got expected );

  return $self;
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
  my ( $self, $file, $arg_name ) = @_;

  return ( sprintf( $FMT_UNDEF, $arg_name, _get_caller_sub() ), undef ) unless defined( $file );

  my $is_real_file = ref( $file ) ne 'SCALAR';
  my $file_stat;
  my $options = $self->options;
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
  my ( $self, $got_file, $expected_file, $got_name, $expected_name ) = @_;

  my ( $got_diag,      $got_data  )     = $self->_get_file_info( $got_file,      $got_name );
  my ( $expected_diag, $expected_data ) = $self->_get_file_info( $expected_file, $expected_name );
  push( @{ $self->diag }, defined( $got_diag ) ? $got_diag : (), defined( $expected_diag ) ? $expected_diag : () );

  return ( $got_data, $expected_data );
}

sub _init {
  my ( $class ) = @_;

  return bless( { diag => [], name => '', options => {} }, $class );
}

sub _relative {
  my ( $self, $file ) = @_;

  return defined( $self->base ) ? path( $file )->relative( $self->base ) : $file ;
}

sub _show_failure {
  my ( $self, @message ) = @_;

  @message = @{ $self->diag } unless @message;
  $Test->ok( 0, $self->name );
  $Test->diag( join( "\n", @message, '' ) );

  return 0;
}

sub _show_result {
  my ( $self, @message ) = @_;

  return @{ $self->diag } ? $self->_show_failure( @message ) : $Test->ok( 1, $self->name );
}

sub _validate_args {
  my ( $self, $expected_type, $dir, $file_list_or_sub, @rest ) = @_;

  $self->_validate_trailing_args( \@rest, $DIRECTORY_OPTIONS );
  return if @{ $self->diag };

  unless ( defined( $dir ) ) {
    $self->diag( [ sprintf( $FMT_UNDEF, '$dir', _get_caller_sub() ) ] );
    return;
  }

  $self->got( path( $dir ) );
  unless ( $self->got->is_dir ) {
    $self->diag( [ sprintf( $FMT_INVALID_DIR, $dir ) ] );
    return;
  }

  if ( ref( $file_list_or_sub ) ne $expected_type ) {
    $self->diag(
      [
        sprintf(
          $FMT_INVALID_ARGUMENT, _get_caller_sub(), ( $expected_type eq 'ARRAY' ? 'array' : 'code' ) . ' reference', '2nd'
        )
      ]
    );
    return;
  }

  return $file_list_or_sub;
}

sub _validate_options {
  my ( $self, $default ) = @_;

  my $options         = $self->options;
  my @invalid_options = grep { !exists( $default->{ $_ } ) } keys( %$options );
  return $self->diag( [ sprintf( $FMT_INVALID_OPTIONS, join( "', '", @invalid_options ) ) ] ) if @invalid_options;

  if ( defined( $options->{ FILTER } ) ) {
    return $self->diag( [ sprintf( $FMT_FILTER_ISNT_CODEREF, _get_caller_sub() ) ] )
      if ref( $options->{ FILTER } ) ne 'CODE';
  }
  else {
    $options->{ FILTER } = $default->{ FILTER };
  }

  if ( exists( $default->{ NAME_PATTERN } ) ) {
    if ( defined( $options->{ NAME_PATTERN } ) ) {
      eval { qr/$options->{ NAME_PATTERN }/ };
      my $error = $@;
      return $self->diag( [ sprintf( $FMT_INVALID_NAME_PATTER, $options->{ NAME_PATTERN }, _get_caller_sub(), $error ) ] )
        if $error;
    }
    else {
      $options->{ NAME_PATTERN } = $default->{ NAME_PATTERN };
    }
  }

  return $self->options( { %$default, %$options } );
}

sub _validate_trailing_args {
  my ( $self, $args, $default ) = @_;

  unless ( @$args ) {                                       # 1st trailing arg omitted: use default options, no title
    $self->options( $default );
    return $self;
  }

  my ( $first_arg, $second_arg ) = @$args;
  my $first_arg_type = ref( $first_arg );

  unless ( $first_arg_type ) {                              # Scalar: use default options and 3rd param as title
    $self->name( $first_arg )->options( $default );
    return $self;
  }

  if  ( $first_arg_type eq 'HASH' ) {                       # Hash reference: forward both options and title
    $self->options( $first_arg )->_validate_options( $default );
    $self->name( $second_arg )->options( { %$default, %{ $self->options } } ) unless @{ $self->diag };
    return $self;
  }

  if ( $first_arg_type eq 'CODE' ) {                        # Code reference: forward filter as option and title
    $self->name( $second_arg )->options( { %$default, FILTER => $first_arg } );
    return $self;
  }

                                                            # Invalid type
  $self->diag( [ sprintf( $FMT_INVALID_ARGUMENT, _get_caller_sub(), 'hash reference / code reference / string', '3rd' ) ] );

  return $self;
}

1;
