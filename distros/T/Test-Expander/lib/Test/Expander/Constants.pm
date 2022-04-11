package Test::Expander::Constants;

our $VERSION = '1.1.1';                                     ## no critic (RequireUseStrict, RequireUseWarnings)

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline portable recursion);

use Const::Fast;
use Exporter         qw(import);
use PadWalker        qw(peek_our);
use Scalar::Readonly qw(readonly_on);
use Test2::Tools::Basic;

readonly_on($VERSION);

const our $ANY_EXTENSION          => qr/ \. [^.]+ $/x;
const our $CLASS_HIERARCHY_LEVEL  => qr/^( \w+ ) (?: :: ( .+ ) )?/x;
const our $ERROR_WAS              => ' Error was: ';
const our $FALSE                  => 0;
const our $EXCEPTION_PREFIX       => 'BEGIN failed--compilation aborted at ';
const our $INVALID_ENV_ENTRY      => "Erroneous line %d of '%s' containing '%s': %s\n";
const our $INVALID_VALUE          => "Option '%s' passed along with invalid value '%s'\n";
const our $KEEP_ENV_VAR           => "Keep environment variable '%s' containing '%s'";
const our $NEW_FAILED             => '%s->new died.%s';
const our $NEW_SUCCEEDED          => "An object of class '%s' isa '%s'";
const our $NOTE                   => sub { my ($format, @args) = @_; note(sprintf($format, @args)) };
const our $REPLACEMENT            => $EXCEPTION_PREFIX . '%s line %s.';
const our $REQUIRE_DESCRIPTION    => 'require %s;%s';
const our $REQUIRE_IMPLEMENTATION => 'package %s; require %s';
const our $SEARCH_PATTERN         => $EXCEPTION_PREFIX . '.*$';
const our $SET_ENV_VAR            => "Set environment variable '%s' to '%s' from file '%s'";
const our $SET_TO                 => "Set %s to '%s'";
const our $TOP_DIR_IN_PATH        => qr{^ ( [^/]+ )}x;
const our $TRUE                   => 1;
const our $UNKNOWN_OPTION         => "Unknown option '%s' => '%s' supplied.\n";
const our $USE_DESCRIPTION        => 'use %s;%s';
const our $USE_IMPLEMENTATION     => 'package %s; use %s%s; 1';
const our $VERSION_NUMBER         => qr/^ \d+ (?: \. \d+ )* $/x;
const our @UNEXPECTED_EXCEPTION   => ('', "Unexpectedly caught exception:\n%s\n");

push(our @EXPORT_OK, keys(%{peek_our(0)}));

1;
