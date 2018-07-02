# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Customer;
$WebService::Braintree::_::Customer::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Customer

=head1 PURPOSE

This class represents a customer.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

use Types::Standard qw(ArrayRef);
use WebService::Braintree::Types qw(
    Address
    AmexExpressCheckoutCard
    AndroidPayCard
    ApplePayCard
    CoinbaseAccount
    CreditCard
    EuropeBankAccount
    MasterpassCard
    PayPalAccount
    UsBankAccount
    VenmoAccount
    VisaCheckoutCard
);

=head1 ATTRIBUTES

=cut

=head2 addresses()

This returns the customer's addresses. This will be an arrayref of
L<WebService::Braintree::_::Address/>.

=cut

has addresses => (
    is => 'ro',
    isa => ArrayRef[Address],
    coerce => 1,
);

=head2 amex_express_checkout_cards()

This returns the customer's Amex Express Checkout cards. This will be an arrayref of
L<WebService::Braintree::_::AmexExpressCheckoutCard/>.

=cut

has amex_express_checkout_cards => (
    is => 'ro',
    isa => ArrayRef[AmexExpressCheckoutCard],
    coerce => 1,
);

=head2 android_pay_cards()

This returns the customer's AndroidPay cards. This will be an arrayref of
L<WebService::Braintree::_::AndroidPayCard/>.

=cut

has android_pay_cards => (
    is => 'ro',
    isa => ArrayRef[AndroidPayCard],
    coerce => 1,
);

=head2 apple_pay_cards()

This returns the customer's ApplePay cards. This will be an arrayref of
L<WebService::Braintree::_::ApplePayCard/>.

=cut

has apple_pay_cards => (
    is => 'ro',
    isa => ArrayRef[ApplePayCard],
    coerce => 1,
);

=head2 coinbase_accounts()

This returns the customer's Coinbase accounts. This will be an arrayref of
L<WebService::Braintree::_::CoinbaseAccount/>.

=cut

has coinbase_accounts => (
    is => 'ro',
    isa => ArrayRef[CoinbaseAccount],
    coerce => 1,
);

=head2 company()

This is the company for this customer.

=cut

has company => (
    is => 'ro',
);

=head2 created_at()

This returns when this customer was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 credit_cards()

This returns the customer's credit cards. This will be an arrayref of
L<WebService::Braintree::_::CreditCard/>.

=cut

has credit_cards => (
    is => 'ro',
    isa => ArrayRef[CreditCard],
    coerce => 1,
);

=head2 custom_fields()

This is the custom fields for this customer.

This will default to C<< {} >>

=cut

has custom_fields => (
    is => 'ro',
    default => sub { {} },
);

=head2 email()

This is the email for this customer.

=cut

has email => (
    is => 'ro',
);

=head2 europe_banks_accounts()

This returns the customer's Europe bank accounts. This will be an arrayref of
L<WebService::Braintree::_::EuropeBankAccount/>.

=cut

has europe_bank_accounts => (
    is => 'ro',
    isa => ArrayRef[EuropeBankAccount],
    coerce => 1,
);

=head2 fax()

This is the fax for this customer.

=cut

has fax => (
    is => 'ro',
);

=head2 first_name()

This is the first name for this customer.

=cut

has first_name => (
    is => 'ro',
);

=head2 id()

This is the ID for this customer.

=cut

has id => (
    is => 'ro',
);

=head2 last_name()

This is the last name for this customer.

=cut

has last_name => (
    is => 'ro',
);

=head2 masterpass_cards()

This returns the customer's Masterpass cards. This will be an arrayref of
L<WebService::Braintree::_::MasterpassCard/>.

=cut

has masterpass_cards => (
    is => 'ro',
    isa => ArrayRef[MasterpassCard],
    coerce => 1,
);

=head2 merchant_id()

This is the merchant ID for this customer.

=cut

has merchant_id => (
    is => 'ro',
);

=head2 paypal_accounts()

This returns the customer's PayPal accounts. This will be an arrayref of
L<WebService::Braintree::_::PayPalAccount/>.

=cut

has paypal_accounts => (
    is => 'ro',
    isa => ArrayRef[PayPalAccount],
    coerce => 1,
);

=head2 phone()

This is the phone for this customer.

=cut

has phone => (
    is => 'ro',
);

=head2 updated_at()

This returns when this customer was last updated.

=cut

has updated_at => (
    is => 'ro',
);

=head2 us_bank_accounts()

This returns the customer's US bank accounts. This will be an arrayref of
L<WebService::Braintree::_::UsBankAccount/>.

=cut

has us_bank_accounts => (
    is => 'ro',
    isa => ArrayRef[UsBankAccount],
    coerce => 1,
);

=head2 venmo_accounts()

This returns the customer's Venmo accounts. This will be an arrayref of
L<WebService::Braintree::_::VenmoAccount/>.

=cut

has venmo_accounts => (
    is => 'ro',
    isa => ArrayRef[VenmoAccount],
    coerce => 1,
);

=head2 visa_checkout_cards()

This returns the customer's VisaCheckout cards. This will be an arrayref of
L<WebService::Braintree::_::VisaCheckoutCard/>.

=cut

has visa_checkout_cards => (
    is => 'ro',
    isa => ArrayRef[VisaCheckoutCard],
    coerce => 1,
);

=head2 website()

This is the website for this customer.

=cut

has website => (
    is => 'ro',
);

=head1 METHODS

=head2 payment_types()

This returns a list of all the payment types supported by this class.

=cut

sub payment_types {
    return qw(
        amex_express_checkout_cards
        android_pay_cards
        apple_pay_cards
        coinbase_accounts
        credit_cards
        europe_bank_accounts
        masterpass_cards
        paypal_accounts
        us_bank_accounts
        venmo_accounts
        visa_checkout_cards
    );
}

=head2 payment_methods()

This returns an arrayref of all available payment methods across all types. The
return value will be in the order specified in L</payment_types()>

=cut

sub payment_methods {
    my $self = shift;

    my @methods = map {
        @{$self->$_ // []}
    } $self->payment_types;

    return \@methods;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
