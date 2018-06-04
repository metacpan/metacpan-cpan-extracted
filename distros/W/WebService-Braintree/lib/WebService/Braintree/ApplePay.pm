# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ApplePay;
$WebService::Braintree::ApplePay::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ApplePay

=head1 PURPOSE

This class lists, registers, and unregisters ApplePay domains.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head2 registered_domains()

This returns a L<response|WebService::Braintee::Result> with the C<< apple_pay_options() >> set.

=cut

sub registered_domains {
    my $class = shift;
    $class->gateway->apple_pay->registered_domains;
}

=head2 register_domain()

This registers the domain provided. This returns a L<response|WebService::Braintee::Result> with nothing set.


=cut

sub register_domain {
    my $class = shift;
    my ($domain) = @_;
    $class->gateway->apple_pay->register_domain($domain);
}

=head2 unregister_domain()

This unregisters the domain provided. This returns a L<response|WebService::Braintee::Result> with nothing set.

=cut

sub unregister_domain {
    my $class = shift;
    my ($domain) = @_;
    $class->gateway->apple_pay->unregister_domain($domain);
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
