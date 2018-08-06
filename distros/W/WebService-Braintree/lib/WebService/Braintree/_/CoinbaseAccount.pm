# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::CoinbaseAccount;
$WebService::Braintree::_::CoinbaseAccount::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::CoinbaseAccount

=head1 PURPOSE

This class represents a Coinbase account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

use Types::Standard qw(ArrayRef);
use WebService::Braintree::Types qw(
    Subscription
);

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

This returns if this card is default.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 subscriptions()

This returns the account's subscriptions. This will be an arrayref of
L<subscriptions|WebService::Braintree::_::Subscription/>.

=cut

has subscriptions => (
    is => 'ro',
    isa => ArrayRef[Subscription],
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

=head2 user_email()

This returns the account's user's email.

=cut

has user_email => (
    is => 'ro',
);

=head2 user_id()

This returns the account's user's ID.

=cut

has user_id => (
    is => 'ro',
);

=head2 user_name()

This returns the account's user's name.

=cut

has user_name => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
