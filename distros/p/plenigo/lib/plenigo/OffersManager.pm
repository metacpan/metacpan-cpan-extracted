package plenigo::OffersManager;

=head1 NAME

 plenigo::OffersManager - Handles plenigo managed offers.

=head1 SYNOPSIS

 use plenigo::OffersManager;

 # Prepare configuration

 my $use_stage = 0; # set if stage system should be used
 my $configuration = plenigo::Configuration->new(access_token => 'ACCESS_TOKEN', use_stage => $use_stage);

 # Get all plenigo offers for the current company. 

 my $offers_manager = plenigo::OffersManager->new(configuration => $configuration);
 my %offer_list = $offers_manager->getAllOffers(0, 10);

 # Get a specific plenigo managed offer.

 my %offer = $offers_manager->getOfferDetail('OFFER_ID');

=head1 DESCRIPTION

 plenigo::OffersManager offers functionality for handling plenigo managed offers.

=cut

use Moo;
use Carp qw(confess);
use plenigo::Ex;
use plenigo::RestClient;

our $VERSION = '3.0001';

has configuration => (
    is       => 'ro',
    required => 1
);

=head2 getOfferDetail($offer_id)

 Get a plenigo managed offers specified by the offer id.

=cut

sub getOfferDetail {
    my ($self, $offer_id) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->get('products/offers/' . $offer_id);
    if ($result{'response_code'} == 404) {
        plenigo::Ex->throw({ code => 404, message => 'There is no offer for the offer id passed.' });
    }
    else {
        return %{$result{'response_content'}};
    }
}

=head2 getAllOffers()

 Get all plenigo managed offers

=cut

sub getAllOffers {
    my ($self, $startingAfter, $size) = @_;
    $size //= 10;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->get('products/offers', { size => $size, startingAfter => $startingAfter });
    return %{$result{'response_content'}};
}

1;
