# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Subscription::Status;
$WebService::Braintree::Subscription::Status::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Subscription::Status

=head1 PURPOSE

This class contains constants for subscription statuses.

=cut

=head1 CONSTANTS

=over 4

=cut

=item Active

=cut

use constant Active => 'Active';

=item Canceled

=cut

use constant Canceled => 'Canceled';

=item Expired

=cut

use constant Expired => 'Expired';

=item Pastdue

=cut

use constant PastDue => 'Past Due';

=item Pending

=cut

use constant Pending => 'Pending';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => (
    Active,
    Canceled,
    Expired,
    PastDue,
    Pending,
);

=back

=cut

1;
__END__
