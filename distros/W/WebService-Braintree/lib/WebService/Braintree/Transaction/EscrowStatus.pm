package WebService::Braintree::Transaction::EscrowStatus;
$WebService::Braintree::Transaction::EscrowStatus::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use constant HoldPending => 'hold_pending';
use constant Held => 'held';
use constant ReleasePending => 'release_pending';
use constant Released => 'released';
use constant Refunded => 'refunded';

use constant All => (
    HoldPending,
    Held,
    ReleasePending,
    Released,
    Refunded
);

1;
__END__
