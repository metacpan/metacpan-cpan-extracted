# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::CreditCard::CardType;
$WebService::Braintree::CreditCard::CardType::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::CreditCard::CardType

=head1 PURPOSE

This class contains a list of constants of credit card card-types.

=cut

=head1 CONSTANTS

=over 4

=cut

=item AmericanExpress

=cut

use constant AmericanExpress => 'American Express';

=item CarteBlanche

=cut

use constant CarteBlanche => 'Carte Blanche';

=item ChinaUnionPay

=cut

use constant ChinaUnionPay => 'China UnionPay';

=item DinersClub

=cut

use constant DinersClub => 'Diners Club';

=item Discover

=cut

use constant Discover => 'Discover';

=item JCB

=cut

use constant JCB => 'JCB';

=item Laser

=cut

use constant Laser => 'Laser';

=item Maestro

=cut

use constant Maestro => 'Maestro';

=item MasterCard

=cut

use constant MasterCard => 'MasterCard';

=item Solo

=cut

use constant Solo => 'Solo';

=item Switch

=cut

use constant Switch => 'Switch';

=item Visa

=cut

use constant Visa => 'Visa';

=item Unknown

=cut

use constant Unknown => 'Unknown';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    AmericanExpress,
    CarteBlanche,
    ChinaUnionPay,
    DinersClub,
    Discover,
    JCB,
    Laser,
    Maestro,
    MasterCard,
    Solo,
    Switch,
    Visa,
    Unknown,
];

=back

=cut

1;
__END__
