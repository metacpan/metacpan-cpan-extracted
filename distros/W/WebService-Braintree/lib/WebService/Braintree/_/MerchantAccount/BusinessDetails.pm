# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::MerchantAccount::BusinessDetails;
$WebService::Braintree::_::MerchantAccount::BusinessDetails::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::MerchantAccount::BusinessDetails

=head1 PURPOSE

This class represents the business details for a merchant account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::MerchantAccount::AddressDetails;

=head1 ATTRIBUTES

=cut

=head2 address()

This is the address for this business detail. This will be an object of type L<WebService::Braintree::_::MerchantAccount::AddressDetails/>.

C<< address_details() >> is an alias for this attribute.

=cut

has address => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount::AddressDetails',
    coerce => 1,
    alias => 'address_details',
);

=head2 dba_name()

This is the DBA (Doing Business As) name for this business detail.

=cut

has dba_name => (
    is => 'ro',
);

=head2 legal_name()

This is the legal name for this business detail.

=cut

has legal_name => (
    is => 'ro',
);

=head2 tax_id()

This is the tax ID for this business detail.

=cut

has tax_id => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
