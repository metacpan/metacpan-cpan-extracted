# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::RiskData;
$WebService::Braintree::_::Transaction::RiskData::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::RiskData

=head1 PURPOSE

This class represents a risk data of a transaction.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 decision()

This is the decision for this risk data.

=cut

has decision => (
    is => 'ro',
);

=head2 device_data_captured()

This is represents if device data has been captured.

=cut

# Coerce this to a boolean?
has device_data_captured => (
    is => 'ro',
);

=head2 id()

This is the id for this risk data.

=cut

has id => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
