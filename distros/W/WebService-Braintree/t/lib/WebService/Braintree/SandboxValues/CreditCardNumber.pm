# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::SandboxValues::CreditCardNumber;

use 5.010_001;
use strictures 1;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(VISA MASTER_CARD FRAUD);
our @EXPORT_OK = qw();

use constant VISA        => '4111111111111111';
use constant MASTER_CARD => '5555555555554444';
use constant FRAUD       => '4000111111111511';

use constant FAILS_VERIFICATION_MASTER_CARD => '5105105105105100';

1;
__END__
