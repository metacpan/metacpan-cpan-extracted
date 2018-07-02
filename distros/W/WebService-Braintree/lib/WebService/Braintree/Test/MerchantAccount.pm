# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Test::MerchantAccount;
$WebService::Braintree::Test::MerchantAccount::VERSION = '1.6';
use 5.010_001;
use strictures 1;

use Exporter;
our @ISA = qw(Exporter);

use constant Approve => "approve_me";
use constant InsufficientFundsContactUs => "insufficient_funds__contact";
use constant AccountNotAuthorizedContactUs => "account_not_authorized__contact";
use constant BankRejectedUpdateFundingInformation => "bank_rejected__update";
use constant BankRejectedNone => "bank_rejected__none";

1;
__END__
