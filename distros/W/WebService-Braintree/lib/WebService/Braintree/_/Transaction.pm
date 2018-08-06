# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction;
$WebService::Braintree::_::Transaction::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction

=head1 PURPOSE

This class represents a transaction.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

use Types::Standard qw(ArrayRef Undef);
use WebService::Braintree::Types qw(
    AddOn
    AuthorizationAdjustment
    Descriptor
    Discount
    Dispute
    ThreeDSecureInfo
    Transaction_AddressDetail
    Transaction_AmexExpressCheckoutDetail
    Transaction_AndroidPayDetail
    Transaction_ApplePayDetail
    Transaction_CoinbaseDetail
    Transaction_CreditCardDetail
    Transaction_CustomerDetail
    Transaction_DisbursementDetail
    Transaction_FacilitatedDetail
    Transaction_FacilitatorDetail
    Transaction_IdealPaymentDetail
    Transaction_MasterpassCardDetail
    Transaction_PayPalDetail
    Transaction_RiskData
    Transaction_StatusDetail
    Transaction_SubscriptionDetail
    Transaction_UsBankAccountDetail
    Transaction_VenmoAccountDetail
    Transaction_VisaCheckoutCardDetail
);

=head2 add_ons()

This returns the transaction's add-ons (if any). This will be an arrayref
of L<WebService::Braintree::_::AddOn/>.

=cut

has add_ons => (
    is => 'ro',
    isa => ArrayRef[AddOn],
    coerce => 1,
);

=head2 additional_processor_response()

This is the additional processor response for this transaction.

=cut

has additional_processor_response => (
    is => 'ro',
);

=head2 amex_express_checkout()

This returns the transaction's AMEX express checkout details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::AmexExpressCheckoutDetail/>.

C<< amex_express_checkout_details() >> is an alias to this attribute.

=cut

has amex_express_checkout => (
    is => 'ro',
    isa => Transaction_AmexExpressCheckoutDetail,
    coerce => 1,
    alias => 'amex_express_checkout_details',
);

=head2 amount()

This is the amount for this transaction.

=cut

# Coerce to "big_decimal"
has amount => (
    is => 'ro',
);

=head2 android_pay()

This returns the transaction's AndroidPay details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::AndroidPayDetail/>.

C<< android_pay_details() >> is an alias to this attribute.

=cut

has android_pay => (
    is => 'ro',
    isa => Transaction_AndroidPayDetail,
    coerce => 1,
    alias => 'android_pay_details',
);

=head2 apple_pay()

This returns the transaction's ApplePay details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::ApplePayDetail/>.

C<< apple_pay_details() >> is an alias to this attribute.

=cut

has apple_pay => (
    is => 'ro',
    isa => Transaction_ApplePayDetail,
    coerce => 1,
    alias => 'apple_pay_details',
);

=head2 authorization_adjustments()

This returns the transaction's authorization adjustments (if any). This will be an arrayref
of L<WebService::Braintree::_::AuthorizationAdjustment/>.

=cut

has authorization_adjustments => (
    is => 'ro',
    isa => ArrayRef[AuthorizationAdjustment],
    coerce => 1,
);

=head2 authorized_transaction_id()

This is the authorized transaction id for this transaction.

=cut

has authorized_transaction_id => (
    is => 'ro',
);

=head2 avs_error_response_code()

This is the avs error response code for this transaction.

=cut

has avs_error_response_code => (
    is => 'ro',
);

=head2 avs_postal_code_response_code()

This is the avs postal code response code for this transaction.

=cut

has avs_postal_code_response_code => (
    is => 'ro',
);

=head2 avs_street_address_response_code()

This is the avs street address response code for this transaction.

=cut

has avs_street_address_response_code => (
    is => 'ro',
);

=head2 billing()

This returns the transaction's billing details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::AddressDetail/>.

C<< billing_details() >> is an alias to this attribute.

=cut

has billing => (
    is => 'ro',
    isa => Transaction_AddressDetail,
    coerce => 1,
    alias => 'billing_details',
);

=head2 channel()

This is the channel for this transaction.

=cut

has channel => (
    is => 'ro',
);

=head2 coinbase()

This returns the transaction's Coinbase details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::CoinbaseDetail/>.

C<< coinbase_details() >> is an alias to this attribute.

=cut

has coinbase => (
    is => 'ro',
    isa => Transaction_CoinbaseDetail,
    coerce => 1,
    alias => 'coinbase_details',
);

=head2 created_at()

This is when this transaction was created.

=cut

# Coerce this to DateTime
has created_at => (
    is => 'ro',
);

=head2 credit_card()

This returns the transaction's credit-card details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::CreditCardDetail/>.

C<< credit_card_details() >> is an alias to this attribute.

=cut

has credit_card => (
    is => 'ro',
    isa => Transaction_CreditCardDetail,
    coerce => 1,
    alias => 'credit_card_details',
);

=head2 currency_iso_code()

This is the currency ISO code for this transaction.

=cut

has currency_iso_code => (
    is => 'ro',
);

=head2 custom_fields()

This is the custom fields for this transaction. This will be a hashref.

=cut

# Require this to be a HashRef (?)
has custom_fields => (
    is => 'ro',
    default => sub { {} },
);

=head2 customer()

This returns the transaction's customer details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::CustomerDetail/>.

C<< customer_details() >> is an alias to this attribute.

=cut

has customer => (
    is => 'ro',
    isa => Transaction_CustomerDetail,
    coerce => 1,
    alias => 'customer_details',
);

=head2 cvv_response_code()

This is the CVV response code for this transaction.

=cut

has cvv_response_code => (
    is => 'ro',
);

=head2 descriptor()

This returns the transaction's descriptor (if any). This will be an object of type L<WebService::Braintree::_::Descriptor/>.

=cut

has descriptor => (
    is => 'ro',
    isa => Descriptor,
    coerce => 1,
);

=head2 disbursement()

This returns the transaction's disbursement details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::DisbursementDetail/>.

C<< disbursement_details() >> is an alias to this attribute.

=cut

has disbursement => (
    is => 'ro',
    isa => Transaction_DisbursementDetail,
    coerce => 1,
    alias => 'disbursement_details',
);

=head2 discount_amount()

This is the discount amount for this transaction.

=cut

has discount_amount => (
    is => 'ro',
);

=head2 discounts()

This returns the transaction's discounts (if any). This will be an arrayref
of L<WebService::Braintree::_::Discount/>.

=cut

has discounts => (
    is => 'ro',
    isa => ArrayRef[Discount],
    coerce => 1,
);

=head2 disputes()

This returns the transaction's disputes (if any). This will be an arrayref
of L<WebService::Braintree::_::Dispute/>.

=cut

has disputes => (
    is => 'ro',
    isa => ArrayRef[Dispute],
    coerce => 1,
);

=head2 escrow_status()

This is the escrow status for this transaction.

=cut

has escrow_status => (
    is => 'ro',
);

=head2 facilitated_details()

This returns the transaction's facilitated details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::FacilitatedDetail/>.

=cut

has facilitated_details => (
    is => 'ro',
    isa => Transaction_FacilitatedDetail,
    coerce => 1,
);

=head2 facilitator_details()

This returns the transaction's facilitator details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::FacilitatorDetail/>.

=cut

has facilitator_details => (
    is => 'ro',
    isa => Transaction_FacilitatorDetail,
    coerce => 1,
);

=head2 gateway_rejection_reason()

This is the gateway rejection reason for this transaction.

=cut

has gateway_rejection_reason => (
    is => 'ro',
);

=head2 id()

This is the id for this transaction.

=cut

has id => (
    is => 'ro',
);

=head2 ideal_payment()

This returns the transaction's IdealPayment details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::IdealPaymentDetail/>.

C<< ideal_payment_details() >> is an alias to this attribute.

=cut

has ideal_payment => (
    is => 'ro',
    isa => Transaction_IdealPaymentDetail,
    coerce => 1,
    alias => 'ideal_payment_details',
);

=head2 masterpass_card()

This returns the transaction's MasterpassCard details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::MasterpassCardDetail/>.

C<< masterpass_card_details() >> is an alias to this attribute.

=cut

has masterpass_card => (
    is => 'ro',
    isa => Transaction_MasterpassCardDetail,
    coerce => 1,
    alias => 'masterpass_card_details',
);

=head2 master_merchant_account_id()

This is the master merchant account id for this transaction.

=cut

has master_merchant_account_id => (
    is => 'ro',
);

=head2 merchant_account_id()

This is the merchant account id for this transaction.

=cut

has merchant_account_id => (
    is => 'ro',
);

=head2 never_expires()

This is true if this transaction never expires.

C<< is_never_expires() >> is an alias for this attribute.

=cut

has never_expires => (
    is => 'ro',
    alias => 'is_never_expires',
);

=head2 options()

This is the options for this transaction.

=cut

has options => (
    is => 'ro',
);

=head2 order_id()

This is the order id for this transaction.

=cut

has order_id => (
    is => 'ro',
);

=head2 partial_settlement_transaction_ids()

This is the partial settlement transaction ids for this transaction.

=cut

has partial_settlement_transaction_ids => (
    is => 'ro',
);

=head2 payment_instrument_type()

This is the payment instrument type for this transaction.

=cut

has payment_instrument_type => (
    is => 'ro',
);

=head2 paypal()

This returns the transaction's PayPal details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::PayPalDetail/>.

C<< paypal_details() >> is an alias to this attribute.

=cut

has paypal => (
    is => 'ro',
    isa => Transaction_PayPalDetail,
    coerce => 1,
    alias => 'paypal_details',
);

=head2 plan_id()

This is the plan id for this transaction.

=cut

has plan_id => (
    is => 'ro',
);

=head2 processor_authorization_code()

This is the process authorization code for this transaction.

=cut

has processor_authorization_code => (
    is => 'ro',
);

=head2 processor_response_code()

This is the processor response code for this transaction.

=cut

has processor_response_code => (
    is => 'ro',
);

=head2 processor_response_text()

This is the processor response text for this transaction.

=cut

has processor_response_text => (
    is => 'ro',
);

=head2 processor_settlement_response_Code()

This is the processor settlement response code for this transaction.

=cut

has processor_settlement_response_code => (
    is => 'ro',
);

=head2 processor_settlement_response_text()

This is the processor settlement response text for this transaction.

=cut

has processor_settlement_response_text => (
    is => 'ro',
);

=head2 purchase_order_number()

This is the purchase order number for this transaction.

=cut

has purchase_order_number => (
    is => 'ro',
);

=head2 recurring()

This is true if this transaction is recurring.

C<< is_recurring() >> is an alias for this attribute.

=cut

has recurring => (
    is => 'ro',
    alias => 'is_recurring',
);

=head2 refund_id()

This is the refund id for this transaction.

=cut

has refund_id => (
    is => 'ro',
);

=head2 refund_ids()

This is the refund ids for this transaction.

=cut

has refund_ids => (
    is => 'ro',
);

=head2 refunded_transaction_id()

This is the refunded transaction id for this transaction.

=cut

has refunded_transaction_id => (
    is => 'ro',
);

=head2 risk_data()

This returns the transaction's risk data details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::RiskData/>.

=cut

has risk_data => (
    is => 'ro',
    isa => Transaction_RiskData,
    coerce => 1,
);

=head2 service_fee_amount()

This is the service fee amount for this transaction.

=cut

# Coerce to "big_decimal"
has service_fee_amount => (
    is => 'ro',
);

=head2 settlement_batch_id()

This is the settlement_batch_id for this transaction.

=cut

has settlement_batch_id => (
    is => 'ro',
);

=head2 shipping_amount()

This is the shipping amount for this transaction.

=cut

has shipping_amount => (
    is => 'ro',
);

=head2 shipping()

This returns the transaction's shipping details (if any). This will be an object of type L<WebService::Braintree::_::Transaction::AddressDetail/>.

C<< shipping_details() >> is an alias to this attribute.

=cut

has shipping => (
    is => 'ro',
    isa => Transaction_AddressDetail,
    coerce => 1,
    alias => 'shipping_details',
);

=head2 ships_from_postal_code()

This is the ships from postal code for this transaction.

=cut

has ships_from_postal_code => (
    is => 'ro',
);

=head2 status()

This is the status for this transaction.

=cut

has status => (
    is => 'ro',
);

=head2 balance()

This is the balance for this transaction.

=cut

has status_history => (
    is => 'ro',
    isa => ArrayRef[Transaction_StatusDetail],
    coerce => 1,
);

=head2 sub_merchant_account_id()

This is the sub merchant account id for this transaction.

=cut

has sub_merchant_account_id => (
    is => 'ro',
);

=head2 balance()

This is the balance for this transaction.

=cut

has subscription => (
    is => 'ro',
    isa => Transaction_SubscriptionDetail,
    coerce => 1,
    alias => 'subscription_details',
);

=head2 subscription_id()

This is the subscription id for this transaction.

=cut

has subscription_id => (
    is => 'ro',
);

=head2 tax_amount()

This is the tax amount for this transaction.

=cut

# Coerce to "big_decimal"
has tax_amount => (
    is => 'ro',
);

=head2 tax_exempt()

This is true if this transaction is tax-exempt.

C<< is_tax_exempt() >> is an alias for this attribute.

=cut

has tax_exempt => (
    is => 'ro',
    alias => 'is_tax_exempt',
);

=head2 balance()

This is the balance for this transaction.

=cut

has three_d_secure_info => (
    is => 'ro',
    isa => ThreeDSecureInfo|Undef,
    coerce => 1,
);

=head2 type()

This is the type for this transaction.

=cut

has type => (
    is => 'ro',
);

=head2 updated_at()

This is when this transaction was last updated. If it has never been updated,
then this should equal the L</created_at> date.

=cut

# Coerce this to a DateTime
has updated_at => (
    is => 'ro',
);

=head2 balance()

This is the balance for this transaction.

=cut

has us_bank_account => (
    is => 'ro',
    isa => Transaction_UsBankAccountDetail,
    coerce => 1,
    alias => 'us_bank_account_details',
);

=head2 balance()

This is the balance for this transaction.

=cut

has venmo_account => (
    is => 'ro',
    isa => Transaction_VenmoAccountDetail,
    coerce => 1,
    alias => 'venmo_account_details',
);

=head2 balance()

This is the balance for this transaction.

=cut

has visa_checkout_card => (
    is => 'ro',
    isa => Transaction_VisaCheckoutCardDetail,
    coerce => 1,
    alias => 'visa_checkout_card_details',
);

=head2 voice_referral_number()

This is the voice referral number for this transaction.

=cut

has voice_referral_number => (
    is => 'ro',
);

=head1 METHODS

=cut

=head2 line_items()

This returns all the line-items.

=cut

sub line_items() {
    my $self = shift;
    WebService::Braintree::TransactionLineItem->find_all($self->id);
}

=head2 is_disbursed()

This returns whether or not the L</disbursement_details> are valid.

=cut

sub is_disbursed {
    shift->disbursement_details->is_valid();
}

=head2 is_refunded()

This returns whether or not this transaction has a refund id.

=cut

# This is going against refund_id, not refund_ids
sub is_refunded {
    my $self = shift;
    !!$self->refund_id
}

=head2 vault_billing_address()

This returns the billing address of the customer.

=cut

sub vault_billing_address {
    my $self = shift;
    return unless $self->billing_details->id;
    WebService::Braintree::Address->find(
        $self->customer_details->id, $self->billing_details->id,
    );
}

=head2 vault_credit_card()

This returns the credit card.

=cut

sub vault_credit_card {
    my $self = shift;
    return unless $self->credit_card_details->token;
    WebService::Braintree::CreditCard->find(
        $self->credit_card_details->id,
    );
}

=head2 vault_customer()

This returns the customer.

=cut

sub vault_customer {
    my $self = shift;
    return unless $self->customer_details->id;
    WebService::Braintree::Customer->find(
        $self->customer_details->id,
    );
}

=head2 vault_shipping_address()

This returns the customer's shipping address.

=cut

sub vault_shipping_address {
    my $self = shift;
    return unless $self->shipping_details->id;
    WebService::Braintree::Address->find(
        $self->customer_details->id, $self->shipping_details->id,
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
