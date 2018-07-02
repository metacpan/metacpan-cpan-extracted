# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::StatusDetail;
$WebService::Braintree::_::Transaction::StatusDetail::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::StatusDetail

=head1 PURPOSE

This class represents a status detail of a transaction.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this status detail.

=cut

has amount => (
    is => 'ro',
);

=head2 status()

This is the status for this status detail.

=cut

has status => (
    is => 'ro',
);

=head2 timestamp()

This is the timestamp for this status detail.

=cut

has timestamp => (
    is => 'ro',
);

=head2 transaction_source()

This is the transaction source for this status detail.

=cut

has transaction_source => (
    is => 'ro',
);

=head2 user()

This is the user for this status detail.

=cut

has user => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
