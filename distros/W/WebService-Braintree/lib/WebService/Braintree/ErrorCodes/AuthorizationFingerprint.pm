package WebService::Braintree::ErrorCodes::AuthorizationFingerprint;
$WebService::Braintree::ErrorCodes::AuthorizationFingerprint::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use constant InvalidCreatedAt                  => "93204";
use constant InvalidFormat                     => "93202";
use constant InvalidPublicKey                  => "93205";
use constant InvalidSignature                  => "93206";
use constant MissingFingerprint                => "93201";
use constant OptionsNotAllowedWithoutCustomer  => "93207";
use constant SignatureRevoked                  => "93203";

1;
__END__
