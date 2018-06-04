# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Dispute::Kind;
$WebService::Braintree::Dispute::Kind::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Dispute::Kind

=head1 PURPOSE

This class contains constants for dispute kinds.

=cut

=head1 CONSTANTS

=over 4

=cut

=item Chargeback

=cut

use constant Chargeback => 'chargeback';

=item PreArbitration

=cut

use constant PreArbitration => 'pre_arbitration';

=item Retrieval

=cut

use constant Retrieval => 'retrieval';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    Chargeback,
    PreArbitration,
    Retrieval,
];

=back

=cut

1;
__END__
