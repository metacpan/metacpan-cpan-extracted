# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::EuropeBankAccount;
$WebService::Braintree::_::EuropeBankAccount::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::EuropeBankAccount

=head1 PURPOSE

This class represents a Europe bank account.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 customer_id()

This is the customer ID for this bank account.

=cut

has customer_id => (
    is => 'ro',
);

=head2 default()

This represents if this account is default.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 image_url()

This is the image URL for this bank account.

=cut

has image_url => (
    is => 'ro',
);

=head2 token()

This is the token for this bank account.

=cut

has token => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
