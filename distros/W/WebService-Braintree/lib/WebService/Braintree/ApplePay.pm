package WebService::Braintree::ApplePay;
$WebService::Braintree::ApplePay::VERSION = '1.0';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ApplePay

=head1 PURPOSE

This class lists, registers, and unregisters ApplePay domains.

=cut

use Moose;
extends "WebService::Braintree::ResultObject";

=head2 registered_domains()

This returns all the registered ApplePay domains

=cut

sub registered_domains {
    my $class = shift;
    $class->gateway->apple_pay->registered_domains;
}

=head2 register_domain()

This registers the domain provided.

=cut

sub register_domain {
    my $class = shift;
    my ($domain) = @_;
    $class->gateway->apple_pay->register_domain($domain);
}

=head2 unregister_domain()

This unregisters the domain provided.

=cut

sub unregister_domain {
    my $class = shift;
    my ($domain) = @_;
    $class->gateway->apple_pay->unregister_domain($domain);
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

sub BUILD {
    my ($self, $attributes) = @_;

    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
