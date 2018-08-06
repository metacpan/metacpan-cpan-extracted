# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::PaymentMethod;
$WebService::Braintree::ErrorCodes::PaymentMethod::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::PaymentMethod

=head1 PURPOSE

This class contains error codes that might be returned if a payment
method is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item CustomerIdIsRequired

=cut

use constant CustomerIdIsRequired => '93104';

=item CustomerIdIsInvalid

=cut

use constant CustomerIdIsInvalid => '93105';

=item CannotForwardPaymentMethodType

=cut

use constant CannotForwardPaymentMethodType => '93106';

=item NonceIsInvalid

=cut

use constant NonceIsInvalid => '93102';

=item NonceIsRequired

=cut

use constant NonceIsRequired => '93103';

=item PaymentMethodParamsAreRequired

=cut

use constant PaymentMethodParamsAreRequired => '93101';

=back

=cut

1;
__END__
