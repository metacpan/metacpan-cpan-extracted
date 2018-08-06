# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::VenmoAccountDetail;
$WebService::Braintree::_::Transaction::VenmoAccountDetail::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::VenmoAccountDetail

=head1 PURPOSE

This class represents a Venmo account detail of a transaction.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 image_url()

This is the image URL for this Venmo account detail.

=cut

has image_url => (
    is => 'ro',
);

=head2 source_description()

This is the source description for this Venmo account detail.

=cut

has source_description => (
    is => 'ro',
);

=head2 token()

This is the token for this Venmo account detail.

=cut

has token => (
    is => 'ro',
);

=head2 username()

This is the username for this Venmo account detail.

=cut

has username => (
    is => 'ro',
);

=head2 venmo_user_id()

This is the Venmo user ID for this Venmo account detail.

=cut

has venmo_user_id => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
