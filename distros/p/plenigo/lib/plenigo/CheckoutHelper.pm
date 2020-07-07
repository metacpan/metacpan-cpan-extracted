package plenigo::CheckoutHelper;

=head1 NAME

 plenigo::CheckoutHelper - A utility class offering support for checkout functionality. 

=head1 SYNOPSIS

 use plenigo::CheckoutHelper;

 my $use_stage = 0; # set if stage system should be used
 my $configuration = plenigo::Configuration->new(access_token => 'ACCESS_TOKEN', use_stage => $use_stage);
 
 my $offer = plenigo::Offer->createPlenigoOffer('CUSTOMER_ID', 'CUSTOMER_IP_ADDRESS', ((plenigoOfferId => 'OFFER_ID1')));
 my $checkout_helper = plenigo::CheckoutHelper->new(configuration => $configuration);
 my $purchase_id = $checkout_helper->getPurchaseId($offer);

=head1 DESCRIPTION

 plenigo::CheckoutHelper provides functionality to prepare a plenigo checkout.

=cut

use Moo;
use Carp qw(confess);
use Crypt::JWT qw(encode_jwt);
use Data::UUID;

our $VERSION = '3.0002';

has configuration => (
    is       => 'ro',
    required => 1
);

=head1 METHODS

=cut

=head2 getPurchaseId($offer)

 Get purchase id necessary for plenigo checkout.

=cut

sub getPurchaseId {
    my ($self, $offer) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->post('checkout/preparePurchase', {}, $offer);

    if ($result{'response_code'} == 404) {
        plenigo::Ex->throw({ code => 404, message => 'There is no customer for the customer id passed.' });
    }

    return %{$result{'response_content'}};
}

1;
