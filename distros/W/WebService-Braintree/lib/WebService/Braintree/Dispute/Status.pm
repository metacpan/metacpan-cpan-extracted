package WebService::Braintree::Dispute::Status;
$WebService::Braintree::Dispute::Status::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use constant Accepted => 'accepted';
use constant Disputed => 'disputed';
use constant Expired => 'expired';
use constant Lost => 'lost';
use constant Open => 'open';
use constant Won => 'won';

1;
__END__
