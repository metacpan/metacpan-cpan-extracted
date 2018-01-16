package WebService::Braintree::Dispute::Reason;
$WebService::Braintree::Dispute::Reason::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use constant CancelledRecurringTransaction => 'cancelled_recurring_transaction';
use constant CreditNotProcessed => 'credit_not_processed';
use constant Duplicate => 'duplicate';
use constant Fraud => 'fraud';
use constant General => 'general';
use constant InvalidAccount => 'invalid_account';
use constant NotRecognized => 'not_recognized';
use constant ProductNotReceived => 'product_not_received';
use constant ProductUnsatisfactory => 'product_unsatisfactory';
use constant Retrieval => 'retrieval';
use constant TransactionAmountDiffers => 'transaction_amount_differs';

1;
__END__
