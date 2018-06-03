# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::VenmoAccount;
$WebService::Braintree::_::VenmoAccount::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::VenmoAccount

=head1 PURPOSE

This class represents a Venmo account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::Subscription;

=head1 ATTRIBUTES

=cut

=head2 created_at()

This returns when this account was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 customer_id()

This returns the account's customer ID.

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

=head2 image_url()

This returns the account's image URL.

=cut

has image_url => (
    is => 'ro',
);

=head2 source_description()

This returns the account's source description.

=cut

has source_description => (
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

=head2 username()

This returns the account's username.

=cut

has username => (
    is => 'ro',
);

=head2 venmo_user_id()

This returns the account's Venmo userid.

=cut

has venmo_user_id => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
