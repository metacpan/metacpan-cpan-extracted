# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Transaction::PaymentInstrumentType;
$WebService::Braintree::Transaction::PaymentInstrumentType::VERSION = '1.3';
use 5.010_001;
use strictures 1;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(PAYPAL_ACCOUNT SEPA_BANK_ACCOUNT CREDIT_CARD ANY UNKNOWN);
our @EXPORT_OK = qw();

=head1 NAME

WebService::Braintree::Transaction::PaymentInstrumentType

=head1 PURPOSE

This class contains constants for transaction payment instrument types.

=cut

=head1 CONSTANTS

=over 4

=cut

=item PAYPAL_ACCOUNT

=cut

use constant PAYPAL_ACCOUNT => 'paypal_account';

=item SEPA_BANK_ACCOUNT

=cut

use constant SEPA_BANK_ACCOUNT => 'sepa_bank_account';

=item CREDIT_CARD

=cut

use constant CREDIT_CARD => 'credit_card';

=item ANY

=cut

use constant ANY => 'any';

=item UNKNOWN

=cut

use constant UNKNOWN => 'unknown';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    PAYPAL_ACCOUNT,
    SEPA_BANK_ACCOUNT,
    CREDIT_CARD,
    ANY,
];

=back

=cut

1;
__END__
