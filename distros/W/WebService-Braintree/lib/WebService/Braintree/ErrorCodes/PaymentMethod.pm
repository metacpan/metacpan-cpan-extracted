package WebService::Braintree::ErrorCodes::PaymentMethod;
$WebService::Braintree::ErrorCodes::PaymentMethod::VERSION = '0.9';
use strict;

use constant CustomerIdIsRequired           => "93104";
use constant CustomerIdIsInvalid            => "93105";
use constant CannotForwardPaymentMethodType => "93106";
use constant NonceIsInvalid                 => "93102";
use constant NonceIsRequired                => "93103";
use constant PaymentMethodParamsAreRequired => "93101";

1;
