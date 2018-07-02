# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::ClientToken;
$WebService::Braintree::ErrorCodes::ClientToken::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::ClientToken

=head1 PURPOSE

This class contains error codes that might be returned if a client token
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item CustomerDoesNotExist

=cut

use constant CustomerDoesNotExist => '92804';

=item FailOnDuplicatePaymentMethodRequiresCustomerId

=cut

use constant FailOnDuplicatePaymentMethodRequiresCustomerId => '92803';

=item MakeDefaultRequiresCustomerId

=cut

use constant MakeDefaultRequiresCustomerId => '92801';

=item ProxyMerchantDoesNotExist

=cut

use constant ProxyMerchantDoesNotExist => '92805';

=item VerifyCardRequiresCustomerId

=cut

use constant VerifyCardRequiresCustomerId => '92802';

=item UnsupportedVersion

=cut

use constant UnsupportedVersion => '92806';

=back

=cut

1;
__END__
