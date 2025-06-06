# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Test::VenmoSdk;
$WebService::Braintree::Test::VenmoSdk::VERSION = '1.7';
use 5.010_001;
use strictures 1;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(generate_test_payment_method_code);

sub generate_test_payment_method_code {
    my($number) = @_;
    return "stub-" . $number;
};

use constant VisaCreditCardNumber => "4111111111111111";
use constant InvalidPaymentMethodCode => "stub-invalid-payment-method-code";
use constant VisaPaymentMethodCode => generate_test_payment_method_code(VisaCreditCardNumber());

use constant InvalidSession => "stub-invalid-session";
use constant Session => "stub-session";

1;
__END__
