# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Result;
$WebService::Braintree::Result::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Result

=head1 PURPOSE

This class represents a result from the Braintree API with no validation errors.

This class is a sibling class to L<WebService::Braintree::PaymentMethodResult>.

=cut

use Moose;

=head1 METHODS

=cut

=head2 Possible objects

These are the possible objects that are returnable by this object. If this
result does not have anything for that method, it will return undef.

=over 4

=item L<add_on|WebService::Braintree::_::AddOn>

=item L<address|WebService::Braintree::_::Address>

=item L<apple_pay_card|WebService::Braintree::_::ApplePayCard>

=item L<apple_pay_options|WebService::Braintree::_::ApplePayOptions>

=item L<credit_card|WebService::Braintree::_::CreditCard>

=item L<credit_card_verification|WebService::Braintree::_::CreditCardVerification>

=item L<customer|WebService::Braintree::_::Customer>

=item L<dispute|WebService::Braintree::_::Dispute>

=item L<discount|WebService::Braintree::_::Discount>

=item L<document_upload|WebService::Braintree::_::DocumentUpload>

=item L<europe_bank_account|WebService::Braintree::_::EuropeBankAccount>

=item L<evidence|WebService::Braintree::_::Dispute::Evidence>

=item L<ideal_payment|WebService::Braintree::_::IdealPayment>

=item L<merchant|WebService::Braintree::_::Merchant>

=item L<merchant_account|WebService::Braintree::_::MerchantAccount>

=item L<payment_method_nonce|WebService::Braintree::_::PaymentMethodNonce>

=item L<paypal_account|WebService::Braintree::_::PayPalAccount>

=item L<settlement_batch_summary|WebService::Braintree::_::SettlementBatchSummary>

=item L<subscription|WebService::Braintree::_::Subscription>

=item L<transaction|WebService::Braintree::_::Transaction>

=item L<us_bank_account|WebService::Braintree::_::UsBankAccount>

=item L<verification|WebService::Braintree::_::CreditCardVerification>

=back

=cut

my $response_objects = {
    add_on => 'WebService::Braintree::_::AddOn',
    address => 'WebService::Braintree::_::Address',
    apple_pay_card => 'WebService::Braintree::_::ApplePayCard',
    apple_pay_options => 'WebService::Braintree::ApplePayOptions',
    credit_card => 'WebService::Braintree::_::CreditCard',
    credit_card_verification => 'WebService::Braintree::_::CreditCardVerification',
    customer => 'WebService::Braintree::_::Customer',
    dispute => 'WebService::Braintree::_::Dispute',
    discount => 'WebService::Braintree::_::Discount',
    document_upload => 'WebService::Braintree::_::DocumentUpload',
    europe_bank_account => 'WebService::Braintree::_::EuropeBankAccount',
    evidence => 'WebService::Braintree::_::Dispute::Evidence',
    ideal_payment => 'WebService::Braintree::IdealPayment',
    merchant => 'WebService::Braintree::_::Merchant',
    merchant_account => 'WebService::Braintree::_::MerchantAccount',
    payment_method_nonce => 'WebService::Braintree::_::PaymentMethodNonce',
    paypal_account => 'WebService::Braintree::_::PayPalAccount',
    settlement_batch_summary => 'WebService::Braintree::_::SettlementBatchSummary',
    subscription => 'WebService::Braintree::_::Subscription',
    transaction => 'WebService::Braintree::_::Transaction',
    us_bank_account => 'WebService::Braintree::_::UsBankAccount',
    verification => 'WebService::Braintree::_::CreditCardVerification',
};

=head2 response

This is the actual response received from Braintree.

=cut

has response => ( is => 'ro' );

my $meta = __PACKAGE__->meta;

sub patch_in_response_accessors {
    my $field_rules = shift;
    while (my($key, $rule) = each(%$field_rules)) {
        $meta->add_method($key => sub {
            my $self = shift;
            my $response = $self->response();
            return if !$response->{$key};

            return $rule->new($response->{$key});
        });
    }
}

patch_in_response_accessors($response_objects);

=head2 is_success

This always returns true.

=cut

sub is_success { 1 }

__PACKAGE__->meta->make_immutable;

1;
__END__
