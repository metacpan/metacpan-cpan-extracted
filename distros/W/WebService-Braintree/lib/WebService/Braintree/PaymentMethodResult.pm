# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::PaymentMethodResult;
$WebService::Braintree::PaymentMethodResult::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::PaymentMethodResult

=head1 PURPOSE

This class represents a result from the Braintree API with no validation errors.
It is specifically used for results from PaymentMethod interfaces.

This class is a sibling class to L<WebService::Braintree::Result>.

=cut

use Moose;

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

has amex_express_checkout_card => (
    is => 'ro',
    isa => 'WebService::Braintree::_::AmexExpressCheckoutCard',
    coerce => 1,
);
has android_pay_card => (
    is => 'ro',
    isa => 'WebService::Braintree::_::AndroidPayCard',
    coerce => 1,
);
has apple_pay_card => (
    is => 'ro',
    isa => 'WebService::Braintree::_::ApplePayCard',
    coerce => 1,
);
has coinbase_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::CoinbaseAccount',
    coerce => 1,
);
has credit_card => (
    is => 'ro',
    isa => 'WebService::Braintree::_::CreditCard',
    coerce => 1,
);
has europe_bank_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::EuropeBankAccount',
    coerce => 1,
);
has masterpass_card => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MasterpassCard',
    coerce => 1,
);
has payment_method_nonce => (
    is => 'ro',
    isa => 'WebService::Braintree::_::PaymentMethodNonce',
    coerce => 1,
);
has paypal_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::PayPalAccount',
    coerce => 1,
);
has us_bank_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::UsBankAccount',
    coerce => 1,
);
has venmo_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::VenmoAccount',
    coerce => 1,
);
has visa_checkout_card => (
    is => 'ro',
    isa => 'WebService::Braintree::_::VisaCheckoutCard',
    coerce => 1,
);
has unknown => (
    is => 'rw',
    isa => 'WebService::Braintree::_::UnknownPaymentMethod',
    coerce => 1,
);

sub BUILD {
    my ($self, $attrs) = @_;

    my $have_item = 0;
    my $meta = __PACKAGE__->meta;
    foreach my $attr ($meta->get_all_attributes) {
        my $name = $attr->name;

        if ($self->$name) {
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

    my $meta = __PACKAGE__->meta;
    foreach my $attr ($meta->get_all_attributes) {
        my $name = $attr->name;
        return $self->$name if $self->$name;
    }

    return;
}

=head2 is_success

This always returns false.

=cut

sub is_success { 1 }

__PACKAGE__->meta->make_immutable;

1;
__END__
