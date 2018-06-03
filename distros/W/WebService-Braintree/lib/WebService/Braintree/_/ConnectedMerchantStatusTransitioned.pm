# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::ConnectedMerchantStatusTransitioned;
$WebService::Braintree::_::ConnectedMerchantStatusTransitioned::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::ConnectedMerchantStatusTransitioned

=head1 PURPOSE

This class represents the transitioning of a connected merchant's status.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 merchant_public_id()

This is the merchant public ID for this status transition.

=cut

has merchant_public_id => (
    is => 'ro',
);

=head2 oauth_application_client_id()

This is the OAuth application client ID for this status transition.

=cut

has oauth_application_client_id => (
    is => 'ro',
);

=head2 status()

This is the status for this status transition.

=cut

has status => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
