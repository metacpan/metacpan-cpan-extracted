package WebService::Braintree::Subscription::Status;
$WebService::Braintree::Subscription::Status::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use constant Active => 'Active';
use constant Canceled => 'Canceled';
use constant Expired => 'Expired';
use constant PastDue => 'Past Due';
use constant Pending => 'Pending';

use constant All => (
    Active,
    Canceled,
    Expired,
    PastDue,
    Pending
);

1;
__END__
