# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::SettlementBatchSummary;
$WebService::Braintree::ErrorCodes::SettlementBatchSummary::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::SettlementBatchSummary

=head1 PURPOSE

This class contains error codes that might be returned if a settlement
batch summary is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item CustomFieldIsInvalid

=cut

use constant CustomFieldIsInvalid => '82303';

=item SettlementDateIsInvalid

=cut

use constant SettlementDateIsInvalid => '82302';

=item SettlementDateIsRequired

=cut

use constant SettlementDateIsRequired => '82301';

=back

=cut

1;
__END__
