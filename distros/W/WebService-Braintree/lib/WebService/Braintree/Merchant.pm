# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Merchant;
$WebService::Braintree::Merchant::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Merchant

=head1 PURPOSE

This class provisions merchants from raw ApplePay.

=cut

use Moo;

with 'WebService::Braintree::Role::Interface';

=head2 provision_raw_apple_pay()

This returns a L<response|WebService::Braintee::Result> with the C<< merchant() >> set.

=cut

sub provision_raw_apple_pay {
    my $class = shift;
    $class->gateway->merchant->provision_raw_apple_apy;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NOTES

This code was transcribed from the Ruby SDK.

=head2 UNTESTED

This class is untested because there is no obvious way to setup the integration
sandbox to trigger these scenarios. If you have a way of testing this, please
reach out to the maintainers.

=cut
