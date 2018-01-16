package WebService::Braintree::Transaction::Source;
$WebService::Braintree::Transaction::Source::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use constant Api => "api";
use constant ControlPanel => "control_panel";
use constant Recurring => "recurring";

use constant All => [Api, ControlPanel, Recurring];

1;
__END__
