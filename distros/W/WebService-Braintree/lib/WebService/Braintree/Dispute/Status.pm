# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Dispute::Status;
$WebService::Braintree::Dispute::Status::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Dispute::Status

=head1 PURPOSE

This class contains constants for dispute statuses.

=cut

=head1 CONSTANTS

=over 4

=cut

=item Accepted

=cut

use constant Accepted => 'accepted';

=item Disputed

=cut

use constant Disputed => 'disputed';

=item Expired

=cut

use constant Expired => 'expired';

=item Lost

=cut

use constant Lost => 'lost';

=item Open

=cut

use constant Open => 'open';

=item Won

=cut

use constant Won => 'won';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    Accepted,
    Disputed,
    Expired,
    Lost,
    Open,
    Won,
];

=back

=cut

1;
__END__
