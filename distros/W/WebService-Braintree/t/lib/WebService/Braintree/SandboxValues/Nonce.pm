# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::SandboxValues::Nonce;

use 5.010_001;
use strictures 1;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw();

use constant TRANSACTABLE => 'fake-valid-nonce';
use constant CONSUMABLE   => 'fake-consumed-nonce';

use constant PAYPAL_ONETIME_PAYMENT => 'fake-paypal-one-time-nonce';
use constant PAYPAL_FUTURE_PAYMENT  => 'fake-paypal-billing-agreement-nonce';

use constant APPLE_PAY_VISA       => 'fake-apple-pay-visa-nonce';
use constant APPLE_PAY_AMEX       => 'fake-apple-pay-amex-nonce';
use constant APPLE_PAY_MASTERCARD => 'fake-apple-pay-mastercard-nonce';

1;
__END__
