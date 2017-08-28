package WebService::Braintree::Transaction::Type;
$WebService::Braintree::Transaction::Type::VERSION = '0.93';
use strict;

use constant Sale => "sale";
use constant Credit => "credit";

use constant All => [Sale, Credit];
1;
