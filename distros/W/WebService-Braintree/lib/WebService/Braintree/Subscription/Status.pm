package WebService::Braintree::Subscription::Status;
$WebService::Braintree::Subscription::Status::VERSION = '0.91';
use strict;

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
