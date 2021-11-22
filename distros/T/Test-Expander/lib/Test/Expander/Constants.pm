## no critic (RequireVersionVar)
package Test::Expander::Constants;

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline portable recursion);

use Const::Fast;
use Exporter  qw(import);
use PadWalker qw(peek_our);

const our $ANY_EXTENSION          => qr/ \. [^.]+ $/x;
const our $CLASS_HIERARCHY_LEVEL  => qr/^( \w+ ) (?: :: ( .+ ) )?/x;
const our $ERROR_WAS              => ' Error was: ';
const our $FALSE                  => 0;
const our $EXCEPTION_PREFIX       => 'BEGIN failed--compilation aborted at ';
const our $INVALID_ENV_ENTRY      => "Erroneous line %d of '%s' containing '%s': %s\n";
const our $INVALID_VALUE          => "Option '%s' passed along with invalid value '%s'\n";
const our $NEW_FAILED             => '%s->new died.%s';
const our $NEW_SUCCEEDED          => "An object of class '%s' isa '%s'";
const our $REPLACEMENT            => $EXCEPTION_PREFIX . '%s line %s.';
const our $REQUIRE_DESCRIPTION    => 'require %s;%s';
const our $REQUIRE_IMPLEMENTATION => 'package %s; require %s';
const our $SEARCH_PATTERN         => $EXCEPTION_PREFIX . '.*$';
const our $TOP_DIR_IN_PATH        => qr{^ ( [^/]+ )}x;
const our $TRUE                   => 1;
const our $UNKNOWN_OPTION         => "Unknown option '%s' => '%s' supplied.\n";
const our $USE_DESCRIPTION        => 'use %s;%s';
const our $USE_IMPLEMENTATION     => 'package %s; use %s%s; 1';
const our $VERSION_NUMBER         => qr/^ \d+ (?: \. \d+ )* $/x;

push(our @EXPORT_OK, keys(%{peek_our(0)}));

1;
