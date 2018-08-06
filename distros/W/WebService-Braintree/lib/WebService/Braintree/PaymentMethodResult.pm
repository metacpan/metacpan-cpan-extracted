# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::PaymentMethodResult;
$WebService::Braintree::PaymentMethodResult::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::PaymentMethodResult

=head1 PURPOSE

This class represents a result from the Braintree API with no validation errors.
It is specifically used for results from PaymentMethod interfaces.

This class is a sibling class to L<WebService::Braintree::Result>.

=cut

use Moo;

use WebService::Braintree::Types qw(
    AmexExpressCheckoutCard
    AndroidPayCard
    ApplePayCard
    CoinbaseAccount
    CreditCard
    EuropeBankAccount
    MasterpassCard
    PaymentMethodNonce
    PayPalAccount
    UsBankAccount
    VenmoAccount
    VisaCheckoutCard
    UnknownPaymentMethod
);

=head1 METHODS

=cut

=head2 Possible objects

These are the possible objects that are returnable by this object. If this
result does not have anything for that method, it will return undef.

=over 4

=item L<amex_express_checkout_card|WebService::Braintree::_::AmexExpressCheckoutCard>

=item L<android_pay_card|WebService::Braintree::_::AndroidPayCard>

=item L<apple_pay_card|WebService::Braintree::_::ApplePayCard>

=item L<coinbase_account|WebService::Braintree::_::CoinbaseAccount>

=item L<credit_card|WebService::Braintree::_::CreditCard>

=item L<europe_bank_account|WebService::Braintree::_::EuropeBankAccount>

=item L<masterpass_card|WebService::Braintree::_::MasterpassCard>

=item L<payment_method_nonce|WebService::Braintree::_::PaymentMethodNonce>

=item L<paypal_account|WebService::Braintree::_::PayPalAccount>

=item L<us_bank_account|WebService::Braintree::_::UsBankAccount>

=item L<venmo_account|WebService::Braintree::_::VenmoAccount>

=item L<visa_checkout_card|WebService::Braintree::_::VisaCheckoutCard>

=item L<unknown|WebService::Braintree::_::UnknownPaymentMethod>

If the response cannot match any of the other possible types, then the result
will be in the C<< unknown() >>.

=back

=cut

my %payment_methods = (
    amex_express_checkout_card => AmexExpressCheckoutCard,
    android_pay_card => AndroidPayCard,
    apple_pay_card => ApplePayCard,
    coinbase_account => CoinbaseAccount,
    credit_card => CreditCard,
    europe_bank_account => EuropeBankAccount,
    masterpass_card => MasterpassCard,
    payment_method_nonce => PaymentMethodNonce,
    paypal_account => PayPalAccount,
    us_bank_account => UsBankAccount,
    venmo_account => VenmoAccount,
    visa_checkout_card => VisaCheckoutCard,
    unknown => UnknownPaymentMethod,
);

while (my ($method, $type) = each %payment_methods) {
    has $method => (
        is => 'ro',
        isa => $type,
        coerce => 1,
    );
}

sub BUILD {
    my ($self, $attrs) = @_;

    my $have_item = 0;
    foreach my $attr (keys %payment_methods) {
        if ($self->$attr) {
            $have_item = 1;
            last;
        }
    }

    $self->unknown((values %$attrs)[0]) unless $have_item;
}

=head2 payment_method()

This will return the value encapsulated in this PaymentMethodResult.

=cut

sub payment_method {
    my $self = shift;

    foreach my $attr (keys %payment_methods) {
        return $self->$attr if $self->$attr;
    }

    return;
}

=head2 is_success

This always returns true.

=cut

sub is_success { 1 }

__PACKAGE__->meta->make_immutable;

1;
__END__
