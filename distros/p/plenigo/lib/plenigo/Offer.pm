package plenigo::Offer;

=head1 NAME

 plenigo::Offer - An offer used during a checkout. 

=head1 SYNOPSIS

 use plenigo::Offer;

 # Create a plenigo offer 

 # Initialize a plenigo managed offer.

 my $offer = plenigo::Offer->createPlenigoOffer('CUSTOMER_ID', 'CUSTOMER_IP_ADDRESS', ((plenigoOfferId => 'OFFER_ID1')));

=head1 DESCRIPTION

 plenigo::Product represents a product during the checkout.

=cut

use Moo;
use Carp qw(confess);

our $VERSION = '3.0000';

has customer_id => (
    is => 'rw'
);

has customer_ip_address => (
    is       => 'rw',
    required => 1
);

has items => (
    is => 'rw',
    required => 1
);

=head2 createPlenigoOffer($offer_id)

 Initialize a plenigo managed offer.

=cut

sub createPlenigoOffer {
    my ($self, $customer_id, $customer_ip_address, @items) = @_;

    my $new_product = plenigo::Product->new(
        customerId        => $customer_id,
        customerIpAddress => $customer_ip_address,
        items             => @items
    );
    return $new_product;
}

1;