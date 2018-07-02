# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Types;

use 5.010_001;
use strictures 1;

use Class::Load qw(try_load_class);
use Hash::Inflator;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

# These are the ones that live in WS::BT::_
my @obj_types = qw(
    AccountUpdaterDailyReport
    AchMandate AddOn Address AmexExpressCheckoutCard AndroidPayCard
    ApplePay ApplePayCard ApplePayOptions
    AuthorizationAdjustment
    BinData CoinbaseAccount
    ConnectedMerchantPayPalStatusChanged
    ConnectedMerchantStatusTransitioned
    CreditCard CreditCardVerification Customer
    Descriptor Disbursement Discount Dispute
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
);

# These are the ones that live in WS::BT
my @class_types = qw(
    ValidationErrorCollection
    ErrorResult
);

foreach my $type_proto (@obj_types) {
    my $class = "WebService::Braintree::_::${type_proto}";

    # Type names cannot have '::' in them, so convert that to '_'
    (my $type = $type_proto) =~ s/::/_/g;

    class_type $type, { class => $class };

    coerce $type,
        from HashRef, via { $class->new($_) };
}

# These are unconverted classes
foreach my $type (@class_types) {
    my $class = "WebService::Braintree::${type}";

    class_type $type, { class => $class };

    coerce $type,
        from HashRef, via { $class->new($_) };
}

class_type HashInflator => { class => 'Hash::Inflator' };
coerce HashInflator =>
    from HashRef, via { Hash::Inflator->new($_) };

# Now, load all the classes here so they don't have to be loaded
# anywhere else.

foreach my $type_proto (@obj_types) {
    my $class = "WebService::Braintree::_::${type_proto}";

    my ($ok, $error) = try_load_class($class);
    $ok ? $class->import : die $error;
}

foreach my $type_proto (@class_types) {
    my $class = "WebService::Braintree::${type_proto}";

    my ($ok, $error) = try_load_class($class);
    $ok ? $class->import : die $error;
}

1;
__END__
