# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::MerchantAccount::FundingDetails;
$WebService::Braintree::_::MerchantAccount::FundingDetails::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::MerchantAccount::FundingDetails

=head1 PURPOSE

This class represents the funding details for a merchant account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 account_number_last_4()

This is the account number last-4 for this funding detail.

=cut

has account_number_last_4 => (
    is => 'ro',
);

=head2 descriptor()

This is the descriptor for this funding detail.

=cut

has descriptor => (
    is => 'ro',
);

=head2 destination()

This is the destination for this funding detail.

=cut

has destination => (
    is => 'ro',
);

=head2 email()

This is the email for this funding detail.

=cut

has email => (
    is => 'ro',
);

=head2 mobile_phone()

This is the mobile phone for this funding detail.

=cut

has mobile_phone => (
    is => 'ro',
);

=head2 routing_number()

This is the routing number for this funding detail.

=cut

has routing_number => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
