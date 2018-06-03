# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Disbursement;
$WebService::Braintree::_::Disbursement::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Disbursement

=head1 PURPOSE

This class represents a disbursement.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::MerchantAccount;

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this disbursement.

=cut

# Coerce to "big_decimal"
has amount => (
    is => 'ro',
);

=head2 disbursement_date()

This is the date of disbursement.

=cut

# Coerce to DateTime
has disbursement_date => (
    is => 'ro',
);

=head2 exception_message()

This is the exception message for this disbursement.

=cut

has exception_message => (
    is => 'ro',
);

=head2 follow_up_action()

This is the follow-up action for this disbursement.

=cut

has follow_up_action => (
    is => 'ro',
);

=head2 id()

This is the id for this disbursement.

=cut

has id => (
    is => 'ro',
);

=head2 merchant_account()

This is the merchant_account for this disbursement. This will be an
object of type L<WebService::Braintree::_::MerchantAccount/>.

=cut

has merchant_account => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount',
    coerce => 1,
);

=head2 retry()

This is the retry for this disbursement.

=cut

has retry => (
    is => 'ro',
);

=head2 success()

This is the success for this disbursement.

=cut

has success => (
    is => 'ro',
);

=head2 transaction_ids()

This is the transaction ids for this disbursement.

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
referenced in this disbursement's L</transaction_ids>.

=cut

sub transactions {
    my $self = shift;
    WebService::Braintree::Transaction->search(sub {
        my $search = shift;
        $search->ids->in($self->transaction_ids);
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
