# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::AuthorizationAdjustment;
$WebService::Braintree::_::AuthorizationAdjustment::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::AuthorizationAdjustment

=head1 PURPOSE

This class represents a authorization adjustment.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this authorization adjustment.

=cut

has amount => (
    is => 'ro',
);

=head2 success()

This is the success for this authorization adjustment.

=cut

has success => (
    is => 'ro',
);

=head2 timestamp()

This is the timestamp for this authorization adjustment.

=cut

has timestamp => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
