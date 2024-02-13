package Test::Expander::Constants;

our $VERSION = '2.5.0';                                     ## no critic (RequireUseStrict, RequireUseWarnings)

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline portable recursion );

use B                qw( svref_2object );
use Const::Fast;
use Exporter         qw( import );
use PadWalker        qw( peek_our );
use Scalar::Readonly qw( readonly_on );
use Test2::Tools::Basic;

readonly_on( $VERSION );

const our $DIE                         => sub { die( sprintf( $_[ 0 ], @_[ 1 .. $#_ ] ) ) };

const our $EXCEPTION_PREFIX            => 'BEGIN failed--compilation aborted at ';

const our $FALSE                       => 0;

const our $FMT_INVALID_COLOR           => "Color '%s' requested for %s variables is not supported\n";
const our $FMT_INVALID_DIRECTORY       => "Invalid directory name / expression '%s' supplied with option '-lib'%s\n";
const our $FMT_INVALID_ENV_ENTRY       => "Erroneous line %d of '%s' containing '%s': %s\n";
const our $FMT_INVALID_VALUE           => "Option '%s' passed along with invalid value '%s'\n";
const our $FMT_INVALID_SUBTEST_NUMBER  => "\nInvalid subtest number: '%s'\n";
const our $FMT_KEEP_ENV_VAR            => "Keep environment variable '%s' containing '%s' because it is not reassigned in file '%s'";
const our $FMT_NEW_FAILED              => '%s->new died.%s';
const our $FMT_NEW_SUCCEEDED           => "An object of class '%s' isa '%s'";
const our $FMT_REPLACEMENT             => $EXCEPTION_PREFIX . '%s line %s.';
const our $FMT_REQUIRE_DESCRIPTION     => 'require %s;%s';
const our $FMT_REQUIRE_IMPLEMENTATION  => 'package %s; require %s';
const our $FMT_SEARCH_PATTERN          => $EXCEPTION_PREFIX . '.*$';
const our $FMT_SET_ENV_VAR             => "Set environment variable '%s' to '%s' from file '%s'";
const our $FMT_SET_TO                  => "Set %s to '%s'";
const our $FMT_SKIP_ENV_VAR            => "Skip environment variable '%s' because its value from file '%s' is undefined";
const our $FMT_UNKNOWN_OPTION          => "Unknown option '%s' => '%s' supplied.\n";
const our $FMT_UNSET_VAR               => "Read-only variable '%s' is not set and not imported";
const our $FMT_USE_DESCRIPTION         => 'use %s;%s';
const our $FMT_USE_IMPLEMENTATION      => 'package %s; use %s%s; 1';

const our $MSG_BAIL_OUT                => 'Test failed.';
const our $MSG_ERROR_WAS               => ' Error was: ';
const our $MSG_UNEXPECTED_EXCEPTION    => 'Unexpectedly caught exception: ';

const our $NOTE                        => sub { my ( $format, @args ) = @_; note( sprintf( $format, @args ) ) };

const our $REGEX_ANY_EXTENSION         => qr/ \. [^.]+ $/x;
const our $REGEX_CLASS_HIERARCHY_LEVEL => qr/^( \w+ ) (?: :: ( .+ ) )?/x;
const our $REGEX_TOP_DIR_IN_PATH       => qr{^ ( [^/]+ ) }x;
const our $REGEX_VERSION_NUMBER        => qr/^ \d+ (?: \. \d+ )* $/x;

const our $TRUE                        => 1;

const our %COLORS                      => ( exported => 'cyan', unexported => 'magenta' );

const our %MOST_CONSTANTS_TO_EXPORT    => (
  '$CLASS'      => sub { $_[ 0 ] },
  '$TEMP_DIR'   => sub { $_[ 0 ] },
  '$TEMP_FILE'  => sub { $_[ 0 ] },
  '$TEST_FILE'  => sub { $_[ 0 ] },
);
const our %REST_CONSTANTS_TO_EXPORT    => (
  '$METHOD'     => sub { $_[ 0 ] },
  '$METHOD_REF' => sub { '\&' . $_[ 1 ] . '::' . svref_2object( $_[ 0 ] )->GV->NAME },
);

push( our @EXPORT_OK, keys( %{ peek_our( 0 ) } ) );

1;
