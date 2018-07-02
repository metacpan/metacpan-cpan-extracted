# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::MerchantAccount::AddressDetails;
$WebService::Braintree::_::MerchantAccount::AddressDetails::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::MerchantAccount::AddressDetails

=head1 PURPOSE

This class represents the address details for a merchant account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 locality()

This is the locality for this address detail.

=cut

has locality => (
    is => 'ro',
);

=head2 postal_code()

This is the postal code for this address detail.

=cut

has postal_code => (
    is => 'ro',
);

=head2 region()

This is the region for this address detail.

=cut

has region => (
    is => 'ro',
);

=head2 street_address()

This is the street address for this address detail.

=cut

has street_address => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
