# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::MerchantAccount::IndividualDetails;
$WebService::Braintree::_::MerchantAccount::IndividualDetails::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::MerchantAccount::IndividualDetails

=head1 PURPOSE

This class represents the individual details for a merchant account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::MerchantAccount::AddressDetails;

=head1 ATTRIBUTES

=cut

=head2 address()

This is the address for this individual detail. This will be an object of type L<WebService::Braintree::_::MerchantAccount::AddressDetails/>.

C<< address_details() >> is an alias for this attribute.

=cut

has address => (
    is => 'ro',
    isa => 'WebService::Braintree::_::MerchantAccount::AddressDetails',
    coerce => 1,
    alias => 'address_details',
);

=head2 date_of_birth()

This is the date of birth for this individual detail.

=cut

has date_of_birth => (
    is => 'ro',
);

=head2 email()

This is the email for this individual detail.

=cut

has email => (
    is => 'ro',
);

=head2 first_name()

This is the first name for this individual detail.

=cut

has first_name => (
    is => 'ro',
);

=head2 last_name()

This is the last name for this individual detail.

=cut

has last_name => (
    is => 'ro',
);

=head2 phone()

This is the phone for this individual detail.

=cut

has phone => (
    is => 'ro',
);

=head2 ssn_last_4()

This is the SSN last-4 for this individual detail.

=cut

has ssn_last_4 => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
