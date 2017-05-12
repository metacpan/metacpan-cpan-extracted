#line 1
package Module::Install::NoAutomatedTesting;

use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.06';

sub no_auto_test {
  return if $Module::Install::AUTHOR;
  exit 0 if $ENV{AUTOMATED_TESTING};
}

'NO SMOKING';

__END__

