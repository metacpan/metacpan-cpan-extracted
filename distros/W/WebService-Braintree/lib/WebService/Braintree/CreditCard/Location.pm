# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::CreditCard::Location;
$WebService::Braintree::CreditCard::Location::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::CreditCard::Location

=head1 PURPOSE

This class contains constants to hold a creditcard customer's location.

=cut

=head1 CONSTANTS

=over 4

=cut

=item International

=cut

use constant International => "international";

=item Us

=cut

use constant US => "us";

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => (
    International,
    US,
);

=back

=cut

1;
__END__
