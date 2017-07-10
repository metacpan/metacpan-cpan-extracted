package WebService::Braintree::ApplePayCard::CardType;
$WebService::Braintree::ApplePayCard::CardType::VERSION = '0.91';
use strict;

use constant AmericanExpress => "Apple Pay - American Express";
use constant MasterCard => "Apple Pay - MasterCard";
use constant Visa => "Apple Pay - Visa";

use constant All => [
    AmericanExpress,
    MasterCard,
    Visa
];

1;
