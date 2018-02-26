package WebService::Braintree::ErrorCodes::DocumentUpload;
$WebService::Braintree::ErrorCodes::DocumentUpload::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use constant KindIsInvalid              => '84901';
use constant FileIsTooLarge             => '84902';
use constant FileTypeIsInvalid          => '84903';
use constant FileIsMalformedOrEncrypted => '84904';
 
1;
__END__
