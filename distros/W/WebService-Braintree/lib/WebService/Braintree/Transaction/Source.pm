package WebService::Braintree::Transaction::Source;
$WebService::Braintree::Transaction::Source::VERSION = '0.93';
use strict;

use constant Api => "api";
use constant ControlPanel => "control_panel";
use constant Recurring => "recurring";

use constant All => [Api, ControlPanel, Recurring];
1;
