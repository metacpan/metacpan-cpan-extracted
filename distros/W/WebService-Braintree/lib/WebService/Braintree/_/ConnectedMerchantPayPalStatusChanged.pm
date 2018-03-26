# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::ConnectedMerchantPayPalStatusChanged;
$WebService::Braintree::_::ConnectedMerchantPayPalStatusChanged::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::ConnectedMerchantPayPalStatusChanged

=head1 PURPOSE

This class represents a PayPal status change for a connected merchant.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 action()

This is the action for this status change.

=cut

has action => (
    is => 'ro',
);

=head2 merchant_public_id()

This is the merchant public ID for this status change.

=cut

has merchant_public_id => (
    is => 'ro',
);

=head2 oauth_application_client_id()

This is the OAuth application client ID for this status change.

=cut

has oauth_application_client_id => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
