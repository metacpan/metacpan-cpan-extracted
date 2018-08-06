# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Transaction::EscrowStatus;
$WebService::Braintree::Transaction::EscrowStatus::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Transaction::EscrowStatus

=head1 PURPOSE

This class contains constants for transaction escrow statuses.

=cut

=head1 CONSTANTS

=over 4

=cut

=item HoldPending

=cut

use constant HoldPending => 'hold_pending';

=item Held

=cut

use constant Held => 'held';

=item ReleasePending

=cut

use constant ReleasePending => 'release_pending';

=item Released

=cut

use constant Released => 'released';

=item Refunded

=cut

use constant Refunded => 'refunded';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => (
    HoldPending,
    Held,
    ReleasePending,
    Released,
    Refunded
);

=back

=cut

1;
__END__
