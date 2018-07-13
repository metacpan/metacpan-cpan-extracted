#line 1
package Module::Install::AutomatedTester;

use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.04';

sub auto_tester {
  return if $Module::Install::AUTHOR;
  return $ENV{AUTOMATED_TESTING};
}

sub cpan_tester {
  &auto_tester;
}

'ARE WE BEING SMOKED?';

__END__

#line 78
