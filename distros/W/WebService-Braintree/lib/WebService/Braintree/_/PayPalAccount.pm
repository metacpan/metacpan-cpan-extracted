# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::PayPalAccount;
$WebService::Braintree::_::PayPalAccount::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::PayPalAccount

=head1 PURPOSE

This class represents a PayPal account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::Subscription;

=head1 ATTRIBUTES

=cut

=head2 billing_agreement_id()

This returns the account's billing agreement ID.

=cut

has billing_agreement_id => (
    is => 'ro',
);

=head2 created_at()

This returns when this account was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 customer_id()

This returns the account's customer's ID.

=cut

has customer_id => (
    is => 'ro',
);

=head2 default()

This returns if this account is default.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 email()

This returns the account's email.

=cut

has email => (
    is => 'ro',
);

=head2 image_url()

This returns the account's image URL.

=cut

has image_url => (
    is => 'ro',
);

=head2 is_channel_initiated()

This returns true if this account is channel-initiated.

=cut

has is_channel_initiated => (
    is => 'ro',
);

=head2 limited_use_order_id()

This returns the account's limited-use order ID.

=cut

has limited_use_order_id => (
    is => 'ro',
);

=head2 payer_info()

This returns the account's payer info.

=cut

has payer_info => (
    is => 'ro',
);

=head2 subscriptions()

This returns the account's subscriptions. This will be an arrayref of
L<subscriptions|WebService::Braintree::_::Subscription/>.

=cut

has subscriptions => (
    is => 'ro',
    isa => 'ArrayRefOfSubscription',
    coerce => 1,
);

=head2 token()

This returns the account's token.

=cut

has token => (
    is => 'ro',
);

=head2 updated_at()

This returns when this account was last updated.

=cut

has updated_at => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
