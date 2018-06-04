# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::DisbursementDetail;
$WebService::Braintree::_::Transaction::DisbursementDetail::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::DisbursementDetail

=head1 PURPOSE

This class represents a transaction disbursement detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this disbursement detail.

=cut

# Coerce this to "big_decimal"
has amount => (
    is => 'ro',
);

=head2 disbursement_date()

This is the disbursement date for this disbursement detail.

=cut

# Coerce this to DateTime
has disbursement_date => (
    is => 'ro',
);

=head2 exception_message()

This is the exception message for this disbursement detail.

=cut

has exception_message => (
    is => 'ro',
);

=head2 follow_up_action()

This is the follow-up action for this disbursement detail.

=cut

has follow_up_action => (
    is => 'ro',
);

=head2 funds_held()

This is the funds held for this disbursement detail.

=cut

has funds_held => (
    is => 'ro',
);

=head2 id()

This is the ID for this disbursement detail.

=cut

has id => (
    is => 'ro',
);

=head2 merchant_account()

This is the merchant_account for this disbursement detail. This will be an
object of type L<WebService::Braintree::_::MerchantAccount/>.

=cut

has merchant_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount',
    coerce => 1,
);

=head2 retry()

This is the retry for this disbursement detail.

=cut

has retry => (
    is => 'ro',
);

=head2 settlement_amount()

This is the settlement amount for this disbursement detail.

=cut

has settlement_amount => (
    is => 'ro',
);

=head2 settlement_currency_exchance_rate()

This is the settlement currency exchange rate for this disbursement detail.

=cut

has settlement_currency_exchange_rate => (
    is => 'ro',
);

=head2 settlement_currency_iso_code()

This is the settlement currency's ISO code for this disbursement detail.

=cut

has settlement_currency_iso_code => (
    is => 'ro',
);

=head2 success()

This is the success for this disbursement detail.

C<< is_success() >> is an alias for this attribute.

=cut

has success => (
    is => 'ro',
    alias => 'is_success',
);

=head2 transaction_ids()

This is the transaction ids for this disbursement detail.

=cut

has transaction_ids => (
    is => 'ro',
);

=head1 METHODS

=head2 is_valid()

This returns true if there is a L</disbursement_date>.

=cut

sub is_valid {
    shift->disbursement_date ? 1 : 0
}

=head2 transactions()

This returns all the L<transactions|WebService::Braintree::_::Transaction>
referenced in this disbursement detail's L</transaction_ids>.

=cut

sub transactions {
    my $self = shift;
    return WebService::Braintree::Transaction->search(sub {
        my $search = shift;
        $search->ids->in($self->transaction_ids);
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
