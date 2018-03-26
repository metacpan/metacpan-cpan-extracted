# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::FacilitatorDetail;
$WebService::Braintree::_::Transaction::FacilitatorDetail::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::FacilitatorDetail

=head1 PURPOSE

This class represents a transaction facilitator detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 oauth_application_client_id()

This is the OAuth application client ID for this transaction facilitator detail.

=cut

has oauth_application_client_id => (
    is => 'ro',
);

=head2 oauth_application_name()

This is the OAuth application name for this transaction facilitator detail.

=cut

has oauth_application_name => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
