# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::SettlementBatchSummary;
$WebService::Braintree::_::SettlementBatchSummary::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::SettlementBatchSummary

=head1 PURPOSE

This class represents a settlement batch summary.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::SettlementBatchSummaryRecord;

=head1 ATTRIBUTES

=cut

=head2 records()

This is the records of the summary. This will be an arrayref of type L<WebService::Braintree::_::SettlementBatchSummaryRecord/>.

=cut

has records => (
    is => 'ro',
    isa => 'ArrayRefOfSettlementBatchSummaryRecord',
    coerce => 1,
);

__PACKAGE__->meta->make_immutable;

1;
__END__
