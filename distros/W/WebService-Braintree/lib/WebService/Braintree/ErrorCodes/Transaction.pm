# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::Transaction;
$WebService::Braintree::ErrorCodes::Transaction::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::Transaction

=head1 PURPOSE

This class contains error codes that might be returned if a transaction
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item AmountCannotBeNegative

=cut

use constant AmountCannotBeNegative => '81501';

=item AmountFormatIsInvalid

=cut

use constant AmountFormatIsInvalid => '81503';

=item AmountIsInvalid

=cut

use constant AmountIsInvalid => '81503';

=item AmountIsRequired

=cut

use constant AmountIsRequired => '81502';

=item AmountIsTooLarge

=cut

use constant AmountIsTooLarge => '81528';

=item AmountMustBeGreaterThanZero

=cut

use constant AmountMustBeGreaterThanZero => '81531';

=item BillingAddressConflict

=cut

use constant BillingAddressConflict => '91530';

=item CannotBeVoided

=cut

use constant CannotBeVoided => '91504';

=item CannotCancelRelease

=cut

use constant CannotCancelRelease => '91562';

=item CannotCloneCredit

=cut

use constant CannotCloneCredit => '91543';

=item CannotCloneTransactionWithVaultCreditCard

=cut

use constant CannotCloneTransactionWithVaultCreditCard => '91540';

=item CannotCloneUnsuccessfulTransaction

=cut

use constant CannotCloneUnsuccessfulTransaction => '91542';

=item CannotCloneVoiceAuthorizations

=cut

use constant CannotCloneVoiceAuthorizations => '91541';

=item CannotHoldInEscrow

=cut

use constant CannotHoldInEscrow => '91560';

=item CannotPartiallyRefundEscrowedTransaction

=cut

use constant CannotPartiallyRefundEscrowedTransaction => '91563';

=item CannotRefundCredit

=cut

use constant CannotRefundCredit => '91505';

=item CannotRefundSettlingTransaction

=cut

use constant CannotRefundSettlingTransaction => '91574';

=item CannotRefundUnlessSettled

=cut

use constant CannotRefundUnlessSettled => '91506';

=item CannotRefundWithPendingMerchantAccount

=cut

use constant CannotRefundWithPendingMerchantAccount => '91559';

=item CannotRefundWithSuspendedMerchantAccount

=cut

use constant CannotRefundWithSuspendedMerchantAccount => '91538';

=item CannotReleaseFromEscrow

=cut

use constant CannotReleaseFromEscrow => '91561';

=item CannotSubmitForSettlement

=cut

use constant CannotSubmitForSettlement => '91507';

=item CannotUpdateTransactionDetailsNotSubmittedForSettlement

=cut

use constant CannotUpdateTransactionDetailsNotSubmittedForSettlement => '915129';

=item CannotSimulateSettlement

=cut

use constant CannotSimulateSettlement => '91575';

=item ChannelIsTooLong

=cut

use constant ChannelIsTooLong => '91550';

=item CreditCardIsRequired

=cut

use constant CreditCardIsRequired => '91508';

=item CustomFieldIsInvalid

=cut

use constant CustomFieldIsInvalid => '91526';

=item CustomFieldIsTooLong

=cut

use constant CustomFieldIsTooLong => '81527';

=item CustomerDefaultPaymentMethodCardTypeIsNotAccepted

=cut

use constant CustomerDefaultPaymentMethodCardTypeIsNotAccepted => '81509';

=item CustomerDoesNotHaveCreditCard

=cut

use constant CustomerDoesNotHaveCreditCard => '91511';

=item CustomerIdIsInvalid

=cut

use constant CustomerIdIsInvalid => '91510';

=item HasAlreadyBeenRefunded

=cut

use constant HasAlreadyBeenRefunded => '91512';

=item MerchantAccountDoesNotSupportMOTO

=cut

use constant MerchantAccountDoesNotSupportMOTO => '91558';

=item MerchantAccountDoesNotSupportRefunds

=cut

use constant MerchantAccountDoesNotSupportRefunds => '91547';

=item MerchantAccountIdIsInvalid

=cut

use constant MerchantAccountIdIsInvalid => '91513';

=item MerchantAccountIsSuspended

=cut

use constant MerchantAccountIsSuspended => '91514';

=item OrderIdIsTooLong

=cut

use constant OrderIdIsTooLong => '91501';

=item PaymentInstrumentNotSupportedByMerchantAccount

=cut

use constant PaymentInstrumentNotSupportedByMerchantAccount => '91577';

=item PaymentMethodConflict

=cut

use constant PaymentMethodConflict => '91515';

=item PaymentMethodConflictWithVenmoSDK

=cut

use constant PaymentMethodConflictWithVenmoSDK => '91549';

=item PaymentMethodDoesNotBelongToCustomer

=cut

use constant PaymentMethodDoesNotBelongToCustomer => '91516';

=item PaymentMethodDoesNotBelongToSubscription

=cut

use constant PaymentMethodDoesNotBelongToSubscription => '91527';

=item PaymentMethodNonceCardTypeIsNotAccepted

=cut

use constant PaymentMethodNonceCardTypeIsNotAccepted => '91567';

=item PaymentMethodNonceConsumed

=cut

use constant PaymentMethodNonceConsumed => '91564';

=item PaymentMethodNonceLocked

=cut

use constant PaymentMethodNonceLocked => '91566';

=item PaymentMethodNonceUnknown

=cut

use constant PaymentMethodNonceUnknown => '91565';

=item PaymentMethodTokenCardTypeIsNotAccepted

=cut

use constant PaymentMethodTokenCardTypeIsNotAccepted => '91517';

=item PaymentMethodTokenIsInvalid

=cut

use constant PaymentMethodTokenIsInvalid => '91518';

=item PayPalNotEnabled

=cut

use constant PayPalNotEnabled => '91576';

=item ProcessorAuthorizationCodeCannotBeSet

=cut

use constant ProcessorAuthorizationCodeCannotBeSet => '91519';

=item ProcessorAuthorizationCodeIsInvalid

=cut

use constant ProcessorAuthorizationCodeIsInvalid => '81520';

=item ProcessorDoesNotSupportCredits

=cut

use constant ProcessorDoesNotSupportCredits => '91546';

=item ProcessorDoesNotSupportVoiceAuthorizations

=cut

use constant ProcessorDoesNotSupportVoiceAuthorizations => '91545';

=item PurchaseOrderNumberIsInvalid

=cut

use constant PurchaseOrderNumberIsInvalid => '91548';

=item PurchaseOrderNumberIsTooLong

=cut

use constant PurchaseOrderNumberIsTooLong => '91537';

=item RefundAmountIsTooLarge

=cut

use constant RefundAmountIsTooLarge => '91521';

=item ServiceFeeAmountCannotBeNegative

=cut

use constant ServiceFeeAmountCannotBeNegative => '91554';

=item ServiceFeeAmountFormatIsInvalid

=cut

use constant ServiceFeeAmountFormatIsInvalid => '91555';

=item ServiceFeeAmountIsTooLarge

=cut

use constant ServiceFeeAmountIsTooLarge => '91556';

=item ServiceFeeAmountNotAllowedOnMasterMerchantAccount

=cut

use constant ServiceFeeAmountNotAllowedOnMasterMerchantAccount => '91557';

=item ServiceFeeIsNotAllowedOnCredits

=cut

use constant ServiceFeeIsNotAllowedOnCredits => '91552';

=item SettlementAmountIsLessThanServiceFeeAmount

=cut

use constant SettlementAmountIsLessThanServiceFeeAmount => '91551';

=item SettlementAmountIsTooLarge

=cut

use constant SettlementAmountIsTooLarge => '91522';

=item SubMerchantAccountRequiresServiceFeeAmount

=cut

use constant SubMerchantAccountRequiresServiceFeeAmount => '91553';

=item SubscriptionDoesNotBelongToCustomer

=cut

use constant SubscriptionDoesNotBelongToCustomer => '91529';

=item SubscriptionIdIsInvalid

=cut

use constant SubscriptionIdIsInvalid => '91528';

=item SubscriptionStatusMustBePastDue

=cut

use constant SubscriptionStatusMustBePastDue => '91531';

=item TaxAmountCannotBeNegative

=cut

use constant TaxAmountCannotBeNegative => '81534';

=item TaxAmountFormatIsInvalid

=cut

use constant TaxAmountFormatIsInvalid => '81535';

=item TaxAmountIsTooLarge

=cut

use constant TaxAmountIsTooLarge => '81536';

=item ThreeDSecureAuthenticationFailed

=cut

use constant ThreeDSecureAuthenticationFailed => '81571';

=item ThreeDSecureTokenIsInvalid

=cut

use constant ThreeDSecureTokenIsInvalid => '91568';

=item ThreeDSecureTransactionDataDoesntMatchVerify

=cut

use constant ThreeDSecureTransactionDataDoesntMatchVerify => '91570';

=item TypeIsInvalid

=cut

use constant TypeIsInvalid => '91523';

=item TypeIsRequired

=cut

use constant TypeIsRequired => '91524';

=item UnsupportedVoiceAuthorization

=cut

use constant UnsupportedVoiceAuthorization => '91539';

=back

=cut

1;
__END__
