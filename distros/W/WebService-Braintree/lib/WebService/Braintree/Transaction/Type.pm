# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Transaction::Type;
$WebService::Braintree::Transaction::Type::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Transaction::Type

=head1 PURPOSE

This class contains constants for transaction types.

=cut

=head1 CONSTANTS

=over 4

=cut

=item Sale

=cut

use constant Sale => 'sale';

=item Credit

=cut

use constant Credit => 'credit';

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => [
    Sale,
    Credit,
];

=back

=cut

1;
__END__
