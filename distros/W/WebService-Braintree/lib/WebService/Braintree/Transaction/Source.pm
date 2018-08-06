# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Transaction::Source;
$WebService::Braintree::Transaction::Source::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Transaction::Source

=head1 PURPOSE

This class contains constants for transaction sources.

=cut

=head1 CONSTANTS

=over 4

=cut

=item Api

=cut

use constant Api => 'api';

=item ControlPanel

=cut

use constant ControlPanel => 'control_panel';

=item Recurring

=cut

use constant Recurring => 'recurring';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    Api,
    ControlPanel,
    Recurring,
];

=back

=cut

1;
__END__
