# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Types;

use 5.010_001;
use strictures 1;

use Hash::Inflator;

use Moose;
use Moose::Util::TypeConstraints;

foreach my $type_proto (qw(
    AccountUpdaterDailyReport
    AchMandate AddOn Address AmexExpressCheckoutCard AndroidPayCard
    ApplePay ApplePayCard
    AuthorizationAdjustment
    BinData CoinbaseAccount
    ConnectedMerchantPayPalStatusChanged
    ConnectedMerchantStatusTransitioned
    CreditCard CreditCardVerification Customer
    Descriptor Disbursement DisbursementDetails Discount Dispute
    DocumentUpload EuropeBankAccount GrantedPaymentInstrumentUpdate
    IbanBankAccount IdealPayment MasterpassCard
    Merchant MerchantAccount PaymentMethodNonce PaymentMethodNonceDetails
    PayPalAccount Plan SettlementBatchSummary SettlementBatchSummaryRecord
    Subscription ThreeDSecureInfo Transaction UnknownPaymentMethod
    UsBankAccount VenmoAccount VisaCheckoutCard WebhookNotification

    Dispute::Evidence Dispute::HistoryEvent
    Dispute::Transaction Dispute::TransactionDetails

    MerchantAccount::AddressDetails MerchantAccount::BusinessDetails
    MerchantAccount::FundingDetails MerchantAccount::IndividualDetails

    Subscription::StatusDetail

    Transaction::AddressDetail
    Transaction::AmexExpressCheckoutDetail
    Transaction::AndroidPayDetail
    Transaction::ApplePayDetail
    Transaction::CoinbaseDetail
    Transaction::CreditCardDetail
    Transaction::CustomerDetail
    Transaction::DisbursementDetail
    Transaction::FacilitatedDetail
    Transaction::FacilitatorDetail
    Transaction::IdealPaymentDetail
    Transaction::MasterpassCardDetail
    Transaction::PayPalDetail
    Transaction::RiskData
    Transaction::StatusDetail
    Transaction::SubscriptionDetail
    Transaction::UsBankAccountDetail
    Transaction::VenmoAccountDetail
    Transaction::VisaCheckoutCardDetail
)) {
    my $class = "WebService::Braintree::_::${type_proto}";

    my $type = $type_proto;
    $type =~ s/:://g;

    subtype "ArrayRefOf${type}",
        as "ArrayRef[${class}]";

    coerce "ArrayRefOf${type}",
        from 'ArrayRef[HashRef]',
        via {[ map { $class->new($_) } @{$_} ]};

    coerce $class,
        from 'HashRef',
        via { $class->new($_) };
}

# These are unconverted classes
foreach my $type (qw(
    ErrorResult ValidationErrorCollection
)) {
    my $class = "WebService::Braintree::${type}";

    subtype "ArrayRefOf${type}",
        as "ArrayRef[$class]";

    coerce "ArrayRefOf${type}",
        from 'ArrayRef[HashRef]',
        via {[ map { $class->new($_) } @{$_} ]};

    coerce $class,
        from 'HashRef',
        via { $class->new($_) };
}

class_type 'Hash::Inflator';
coerce 'Hash::Inflator',
    from 'HashRef',
    via { Hash::Inflator->new($_) };

1;
__END__
