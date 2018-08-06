# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::AmexExpressCheckoutDetail;
$WebService::Braintree::_::Transaction::AmexExpressCheckoutDetail::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::AmexExpressCheckoutDetail

=head1 PURPOSE

This class represents a transaction AmexExpress checkout detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 bin()

This is the bin for this transaction AmexExpress checkout detail.

=cut

has bin => (
    is => 'ro',
);

=head2 card_member_expiry_date()

This is the card member expiry date for this transaction AmexExpress checkout detail.

=cut

has card_member_expiry_date => (
    is => 'ro',
);

=head2 card_member_number()

This is the card member number for this transaction AmexExpress checkout detail.

=cut

has card_member_number => (
    is => 'ro',
);

=head2 card_type()

This is the card type for this transaction AmexExpress checkout detail.

=cut

has card_type => (
    is => 'ro',
);

=head2 expiration_month()

This is the expiration month for this transaction ApplePay detail.

=cut

has expiration_month => (
    is => 'ro',
);

=head2 expiration_year()

This is the expiration year for this transaction ApplePay detail.

=cut

has expiration_year => (
    is => 'ro',
);

=head2 image_url()

This is the image url for this transaction AmexExpress checkout detail.

=cut

# Coerce this to URI
has image_url => (
    is => 'ro',
);

=head2 source_description()

This is the source description for this transaction AmexExpress checkout detail.

=cut

has source_description => (
    is => 'ro',
);

=head2 token()

This is the token for this transaction AmexExpress checkout detail.

=cut

has token => (
    is => 'ro',
);

=head1 METHODS

=head2 expiration_date()

This returns the expiration date in MM/YYYY format.

=cut

sub expiration_date {
    my $self = shift;
    $self->expiration_month . '/' . $self->expiration_year;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
