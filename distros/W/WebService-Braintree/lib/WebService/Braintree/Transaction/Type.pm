package WebService::Braintree::Transaction::Type;
$WebService::Braintree::Transaction::Type::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use constant Sale => "sale";
use constant Credit => "credit";

use constant All => [Sale, Credit];

1;
__END__
