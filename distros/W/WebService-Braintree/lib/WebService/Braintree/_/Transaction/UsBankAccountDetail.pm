# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::UsBankAccountDetail;
$WebService::Braintree::_::Transaction::UsBankAccountDetail::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::UsBankAccountDetail

=head1 PURPOSE

This class represents a transaction US bank account detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::AchMandate;

=head1 ATTRIBUTES

=cut

=head2 account_holder_name()

This is the account holder name for this US bank account detail.

=cut

has account_holder_name => (
    is => 'ro',
);

=head2 account_type()

This is the account type for this US bank account detail.

=cut

has account_type => (
    is => 'ro',
);

=head2 ach_mandate()

This is the ACH mandate for this US bank account detail. This will be an
object of type L<WebService::Braintree::_::AchMandate/>.

=cut

has ach_mandate => (
    is => 'ro',
    isa => 'WebService::Braintree::_::AchMandate',
    coerce => 1,
);

=head2 bank_name()

This is the bank name for this US bank account detail.

=cut

has bank_name => (
    is => 'ro',
);

=head2 image_url()

This is the image URL for this US bank account detail.

=cut

has image_url => (
    is => 'ro',
);

=head2 last_4()

This is the last-4 for this US bank account detail.

=cut

has last_4 => (
    is => 'ro',
);

=head2 routing_number()

This is the routing number for this US bank account detail.

=cut

has routing_number => (
    is => 'ro',
);

=head2 token()

This is the token for this US bank account detail.

=cut

has token => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
