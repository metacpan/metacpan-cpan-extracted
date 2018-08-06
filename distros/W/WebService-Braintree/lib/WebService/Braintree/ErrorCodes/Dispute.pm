# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::Dispute;
$WebService::Braintree::ErrorCodes::Dispute::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::Dispute

=head1 PURPOSE

This class contains error codes that might be returned if a dispute is
incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item CanOnlyAddEvidenceToOpenDispute

=cut

use constant CanOnlyAddEvidenceToOpenDispute => '95701';

=item CanOnlyRemoveEvidenceFromOpenDispute

=cut

use constant CanOnlyRemoveEvidenceFromOpenDispute => '95702';

=item CanOnlyAddEvidenceDocumentToDispute

=cut

use constant CanOnlyAddEvidenceDocumentToDispute => '95703';

=item CanOnlyAcceptOpenDispute

=cut

use constant CanOnlyAcceptOpenDispute => '95704';

=item CanOnlyFinalizeOpenDispute

=cut

use constant CanOnlyFinalizeOpenDispute => '95705';

=back

=cut

1;
__END__
