package WebService::Braintree::Test::MerchantAccount;
$WebService::Braintree::Test::MerchantAccount::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Exporter qw(import);
our @ISA = qw(Exporter);

use constant Approve => "approve_me";
use constant InsufficientFundsContactUs => "insufficient_funds__contact";
use constant AccountNotAuthorizedContactUs => "account_not_authorized__contact";
use constant BankRejectedUpdateFundingInformation => "bank_rejected__update";
use constant BankRejectedNone => "bank_rejected__none";

1;
__END__
