package WebService::Braintree::ApplePayCard::CardType;
$WebService::Braintree::ApplePayCard::CardType::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use constant AmericanExpress => "Apple Pay - American Express";
use constant MasterCard => "Apple Pay - MasterCard";
use constant Visa => "Apple Pay - Visa";

use constant All => [
    AmericanExpress,
    MasterCard,
    Visa
];

1;
__END__
