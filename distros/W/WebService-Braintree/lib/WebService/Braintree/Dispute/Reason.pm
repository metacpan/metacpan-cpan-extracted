# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Dispute::Reason;
$WebService::Braintree::Dispute::Reason::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Dispute::Reason

=head1 PURPOSE

This class contains constants for dispute reasons.

=cut

=head1 CONSTANTS

=over 4

=cut

=item CancelledRecurringTransaction

=cut

use constant CancelledRecurringTransaction => 'cancelled_recurring_transaction';

=item CreditNotProcessed

=cut

use constant CreditNotProcessed => 'credit_not_processed';

=item Duplicate

=cut

use constant Duplicate => 'duplicate';

=item Fraud

=cut

use constant Fraud => 'fraud';

=item General

=cut

use constant General => 'general';

=item InvalidAccount

=cut

use constant InvalidAccount => 'invalid_account';

=item NotRecognized

=cut

use constant NotRecognized => 'not_recognized';

=item ProductNotReceived

=cut

use constant ProductNotReceived => 'product_not_received';

=item ProductUnsatisfactory

=cut

use constant ProductUnsatisfactory => 'product_unsatisfactory';

=item Retrieval

=cut

use constant Retrieval => 'retrieval';

=item TransactionAmountDiffers

=cut

use constant TransactionAmountDiffers => 'transaction_amount_differs';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    CancelledRecurringTransaction,
    CreditNotProcessed,
    Duplicate,
    Fraud,
    General,
    InvalidAccount,
    NotRecognized,
    ProductNotReceived,
    ProductUnsatisfactory,
    Retrieval,
    TransactionAmountDiffers,
];

=back

=cut

1;
__END__
