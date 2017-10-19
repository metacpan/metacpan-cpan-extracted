package WebService::Braintree::ErrorCodes::MerchantAccount::Individual::Address;
$WebService::Braintree::ErrorCodes::MerchantAccount::Individual::Address::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use constant StreetAddressIsRequired => "82657";
use constant LocalityIsRequired      => "82658";
use constant PostalCodeIsRequired    => "82659";
use constant RegionIsRequired        => "82660";
use constant StreetAddressIsInvalid  => "82661";
use constant PostalCodeIsInvalid     => "82662";
use constant RegionIsInvalid         => "82668";

1;
__END__
