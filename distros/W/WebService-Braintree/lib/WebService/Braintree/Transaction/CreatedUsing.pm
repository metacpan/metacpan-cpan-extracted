# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Transaction::CreatedUsing;
$WebService::Braintree::Transaction::CreatedUsing::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Transaction::CreatedUsing

=head1 PURPOSE

This class contains constants for what a transaction is created with.

=cut

=head1 CONSTANTS

=over 4

=cut

=item Token

=cut

use constant Token => 'token';

=item FullInformation

=cut

use constant FullInformation => 'full_information';


=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => (
    Token,
    FullInformation,
);

=back

=cut

1;
__END__
