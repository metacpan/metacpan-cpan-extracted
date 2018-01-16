package WebService::Braintree::Merchant;
$WebService::Braintree::Merchant::VERSION = '1.0';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Merchant

=head1 PURPOSE

This class provisions merchants from raw ApplePay.

=cut

use Moose;
extends "WebService::Braintree::ResultObject";

=head2 provision_raw_apple_pay()

This provisions a merchant from raw apple_pay

=cut

sub provision_raw_apple_pay {
    my $class = shift;
    $class->gateway->merchant->provision_raw_apple_apy;
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
