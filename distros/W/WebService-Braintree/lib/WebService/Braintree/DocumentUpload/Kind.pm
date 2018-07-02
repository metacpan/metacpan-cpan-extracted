# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::DocumentUpload::Kind;
$WebService::Braintree::DocumentUpload::Kind::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::DocumentUpload::Kind

=head1 PURPOSE

This class contains constants for kinds of document uploads.

=cut

=head1 CONSTANTS

=over 4

=cut

=item EvidenceDocument

=cut

use constant EvidenceDocument => 'evidence_document';

=item IdentityDocument

=cut

use constant IdentityDocument => 'identity_document';

=item PayoutInvoiceDocument

=cut

use constant PayoutInvoiceDocument => 'payout_invoice_document';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    EvidenceDocument,
    IdentityDocument,
    PayoutInvoiceDocument,
];

=back

=cut

1;
__END__
