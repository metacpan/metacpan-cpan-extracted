# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ApplePayCard::CardType;
$WebService::Braintree::ApplePayCard::CardType::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ApplePayCard::CardType

=head1 PURPOSE

This class contains constants for ApplePay card types.

=cut

=head1 CONSTANTS

=over 4

=cut

=item AmericanExpress

=cut

use constant AmericanExpress => "Apple Pay - American Express";

=item MasterCard

=cut

use constant MasterCard => "Apple Pay - MasterCard";

=item Visa

=cut

use constant Visa => "Apple Pay - Visa";

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    AmericanExpress,
    MasterCard,
    Visa
];

=back

=cut

1;
__END__
