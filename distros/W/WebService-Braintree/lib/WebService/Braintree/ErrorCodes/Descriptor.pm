package WebService::Braintree::ErrorCodes::Descriptor;
$WebService::Braintree::ErrorCodes::Descriptor::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use constant DynamicDescriptorsDisabled        => "92203";
use constant InternationalPhoneFormatIsInvalid => "92205";
use constant InternationalNameFormatIsInvalid  => "92204";
use constant NameFormatIsInvalid               => "92201";
use constant PhoneFormatIsInvalid              => "92202";
use constant UrlFormatIsInvalid                => "92206";

1;
__END__
