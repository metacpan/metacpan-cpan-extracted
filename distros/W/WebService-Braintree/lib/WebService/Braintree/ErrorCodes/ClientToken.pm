package WebService::Braintree::ErrorCodes::ClientToken;
$WebService::Braintree::ErrorCodes::ClientToken::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use constant CustomerDoesNotExist                            => "92804";
use constant FailOnDuplicatePaymentMethodRequiresCustomerId  => "92803";
use constant MakeDefaultRequiresCustomerId                   => "92801";
use constant ProxyMerchantDoesNotExist                       => "92805";
use constant VerifyCardRequiresCustomerId                    => "92802";
use constant UnsupportedVersion                              => "92806";

1;
__END__
