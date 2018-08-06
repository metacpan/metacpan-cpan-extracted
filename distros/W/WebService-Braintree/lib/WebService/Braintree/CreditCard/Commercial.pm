# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::CreditCard::Commercial;
$WebService::Braintree::CreditCard::Commercial::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::CreditCard::Commercial

=head1 PURPOSE

This class contains constants to state whether a creditcard is commercial.

=cut

=head1 CONSTANTS

=over 4

=cut

=item Yes

=cut

use constant Yes => 'Yes';

=item No

=cut

use constant No => 'No';

=item Unknown

=cut

use constant Unknown => 'Unknown';

=back

=cut

1;
__END__
