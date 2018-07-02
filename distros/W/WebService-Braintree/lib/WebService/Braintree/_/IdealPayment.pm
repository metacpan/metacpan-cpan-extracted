# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::IdealPayment;
$WebService::Braintree::_::IdealPayment::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::IdealPayment

=head1 PURPOSE

This class represents a Ideal payment.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

use WebService::Braintree::Types qw(
    IbanBankAccount
);

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this ideal payment.

=cut

has amount => (
    is => 'ro',
);

=head2 approval_url()

This is the approval URL for this ideal payment.

=cut

has approval_url => (
    is => 'ro',
);

=head2 currency()

This is the currency for this ideal payment.

=cut

has currency => (
    is => 'ro',
);

=head2 iban_bank_account()

This is the iban_bank_account for this ideal payment. This will be an object of type L<WebService::Braintree::_::IbanBankAccount/>.

=cut

has iban_bank_account => (
    is => 'ro',
    isa => IbanBankAccount,
    coerce => 1,
);

=head2 id()

This is the ID for this ideal payment.

=cut

has id => (
    is => 'ro',
);

=head2 ideal_transaction_id()

This is the ideal transaction ID for this ideal payment.

=cut

has ideal_transaction_id => (
    is => 'ro',
);

=head2 issuer()

This is the issuer for this ideal payment.

=cut

has issuer => (
    is => 'ro',
);

=head2 order_id()

This is the order ID for this ideal payment.

=cut

has order_id => (
    is => 'ro',
);

=head2 status()

This is the status for this ideal payment.

=cut

has status => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
