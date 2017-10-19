package WebService::Braintree::ErrorCodes::MerchantAccount::Individual;
$WebService::Braintree::ErrorCodes::MerchantAccount::Individual::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use constant FirstNameIsRequired    => "82637";
use constant LastNameIsRequired     => "82638";
use constant DateOfBirthIsRequired  => "82639";
use constant SsnIsInvalid           => "82642";
use constant EmailIsInvalid         => "82643";
use constant FirstNameIsInvalid     => "82644";
use constant LastNameIsInvalid      => "82645";
use constant PhoneIsInvalid         => "82656";
use constant DateOfBirthIsInvalid   => "82666";
use constant EmailIsRequired        => "82667";

1;
__END__
