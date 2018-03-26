# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::GrantedPaymentInstrumentUpdate;
$WebService::Braintree::_::GrantedPaymentInstrumentUpdate::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::GrantedPaymentInstrumentUpdate

=head1 PURPOSE

This class represents an update to a granted payment instrument.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 grant_owner_merchant_id()

This is the grant owner merchant ID for this update.

=cut

has grant_owner_merchant_id => (
    is => 'ro',
);

=head2 grant_recipient_merchant_id()

This is the grant recipient merchant ID for this update.

=cut

has grant_recipient_merchant_id => (
    is => 'ro',
);

=head2 payment_method_nonce()

This is the payment method nonce for this update.

=cut

has payment_method_nonce => (
    # q.v. BUILD() for why this is 'rw' instead of 'ro'
    is => 'rw',
);

=head2 token()

This is the token for this update.

=cut

has token => (
    is => 'ro',
);

=head2 updated_fields()

This is the updated fields for this update.

=cut

has updated_fields => (
    is => 'ro',
);

sub BUILD {
    my $self = shift;

    # This is in the Ruby SDK. I'm not sure why we want to do this.
    $self->payment_method_nonce(
        $self->payment_method_nonce->{nonce},
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
