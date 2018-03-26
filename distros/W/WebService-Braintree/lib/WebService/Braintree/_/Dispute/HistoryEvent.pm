# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Dispute::HistoryEvent;
$WebService::Braintree::_::Dispute::HistoryEvent::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Dispute::HistoryEvent

=head1 PURPOSE

This class represents a history event of a dispute.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 status()

This is the status for this history event.

=cut

has status => (
    is => 'ro',
);

=head2 timestamp()

This is the timestamp for this history event.

=cut

has timestamp => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
