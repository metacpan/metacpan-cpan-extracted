package WebService::Braintree::AddOn;
$WebService::Braintree::AddOn::VERSION = '1.0';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::AddOn

=head1 PURPOSE

This class lists all add-ons

=cut

use Moose;
extends "WebService::Braintree::ResultObject";

=head2 all()

This returns all the add-ons.

=cut

sub all {
    my $class = shift;
    $class->gateway->add_on->all;
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
