# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::SettlementBatchSummary;
$WebService::Braintree::SettlementBatchSummary::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::SettlementBatchSummary

=head1 PURPOSE

This class generates settlement batch summaries.

=head1 EXPLANATION

TODO

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 generate()

This method takes a settlement date and an optional group_by_custom_field and
generates a settlement batch summary.

=cut

sub generate {
    my($class, $settlement_date, $group_by_custom_field) = @_;
    $class->gateway->settlement_batch_summary->generate($settlement_date, $group_by_custom_field);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
