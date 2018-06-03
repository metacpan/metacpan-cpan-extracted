# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Transaction::Status;
$WebService::Braintree::Transaction::Status::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Transaction::Status

=head1 PURPOSE

This class contains constants for transaction statuses.

=cut

=head1 CONSTANTS

=over 4

=cut

=item AuthorizationExpired

=cut

use constant AuthorizationExpired => 'authorization_expired';

=item Authorizing

=cut

use constant Authorizing => 'authorizing';

=item Authorized

=cut

use constant Authorized => 'authorized';

=item GatewayRejected

=cut

use constant GatewayRejected => 'gateway_rejected';

=item Failed

=cut

use constant Failed => 'failed';

=item ProcessorDeclined

=cut

use constant ProcessorDeclined => 'processor_declined';

=item Settled

=cut

use constant Settled => 'settled';

=item Settling

=cut

use constant Settling => 'settling';

=item SubmittedForSettlement

=cut

use constant SubmittedForSettlement => 'submitted_for_settlement';

=item SettlementDeclined

=cut

use constant SettlementDeclined => 'settlement_declined';

=item SettlementPending

=cut

use constant SettlementPending => 'settlement_pending';

=item Voided

=cut

use constant Voided => 'voided';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => (
    AuthorizationExpired,
    Authorizing,
    Authorized,
    GatewayRejected,
    Failed,
    ProcessorDeclined,
    Settled,
    SettlementDeclined,
    SettlementPending,
    Settling,
    SubmittedForSettlement,
    Voided,
);

=back

=cut

1;
__END__
