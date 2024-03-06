package Test::Files::Constants;

our $VERSION = '0.25';                                      ## no critic (RequireUseStrict, RequireUseWarnings)

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline portable recursion );

use Const::Fast qw( const );
use Exporter    qw( import );
use PadWalker   qw( peek_our );

const our $DIRECTORY_OPTIONS       => {
  EXISTENCE_ONLY => 0,
  FILTER         => undef,
  NAME_PATTERN   => '.',
  RECURSIVE      => 0,
  SIZE_ONLY      => 0,
  SYMMETRIC      => 0,
};
const our $ARCHIVE_OPTIONS         => {
  %$DIRECTORY_OPTIONS,
  EXTRACT        => sub {},
  META_DATA      => sub {},
};
const our $FILE_OPTIONS            => {
  EXISTENCE_ONLY => 0,
  FILTER         => undef,
  SIZE_ONLY      => 0,
};

const our $EXPECTED_CONTENT        => '<expected content>';

const our $FMT_ABSENT              => "'%s' is absent, or is a directory, or is a special file";
const our $FMT_ABSENT_WITH_ERROR   => "'%s' is absent, error: %s";
const our $FMT_CANNOT_CREATE_DIR   => "Cannot create directory '%s': %s";
const our $FMT_CANNOT_EXTRACT      => "Cannot extract from '%s' to directory '%s': %s";
const our $FMT_CANNOT_GET_METADATA => "Cannot get metadata from '%s': %s";
const our $FMT_DIFFERENT_SIZE      => "'%s' and '%s' have different sizes: %d and %d bytes, correspondingly";
const our $FMT_FAILED_TO_SEE       => "Failed to see '%s'";
const our $FMT_FILTER_ISNT_CODEREF => "Filter supplied to '%s' must be a code reference (or undef)";
const our $FMT_FIRST_FILE_ABSENT   => "'%s' is present but '%s' is absent";
const our $FMT_INVALID_ARGUMENT    => "'%s' requires %s as %s argument";
const our $FMT_INVALID_DIR         => "'%s' is not a valid directory";
const our $FMT_INVALID_NAME_PATTER => "Name pattern '%s' supplied to '%s' is invalid: %s";
const our $FMT_INVALID_OPTIONS     => "Invalid options detected: '%s'";
const our $FMT_SECOND_FILE_ABSENT  => "'%s' is absent but '%s' is present";
const our $FMT_SUB_FAILED          => "Passed subroutine failed for '%s'";
const our $FMT_UNDEF               => "Argument '%s' of '%s' must be a string or a Path::Tiny object";
const our $FMT_UNEXPECTED          => "Unexpectedly saw: '%s'";

const our $UNKNOWN                 => '<unknown>';

const our %DIFF_OPTIONS            => (
  CONTEXT     => 3,                                         # change this one later if needed
  FILENAME_A  => 'Got',
  FILENAME_B  => 'Expected',
  INDEX_LABEL => 'Ln',
  KEYGEN      => undef,
  KEYGEN_ARGS => undef,
  MTIME_A     => undef,
  MTIME_B     => undef,
  OFFSET_A    => 1,
  OFFSET_B    => 1,
  OUTPUT      => undef,
  STYLE       => 'Unified',
);

push( our @EXPORT_OK, keys( %{ peek_our( 0 ) } ) );

1;
