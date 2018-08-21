package plenigo::ProductsManager;

=head1 NAME

 plenigo::ProductsManager - Handles plenigo managed products.

=head1 SYNOPSIS

 use plenigo::ProductsManager;

 # Prepare configuration

 my $configuration = plenigo::Configuration->new(company_id => 'YOUR_COMPANY_ID, secret => 'YOUR_SECRET');

 # Get all plenigo products for the current company. 

 my $products_manager = plenigo::access::ProductsManager->new(configuration => $configuration);
 my %product_list = $products_manager->getAllProducts(0, 10);

 # Get a specific plenigo managed product.

 my %product = $products_manager->getProductDetail('PRODUCT_ID');

=head1 DESCRIPTION

 plenigo::ProductsManager offers functionality for handling plenigo managed products.

=cut

use Moo;
use Carp qw(confess);
use Carp::Always;
use plenigo::Ex;
use plenigo::RestClient;

our $VERSION = '2.0003';

has configuration => (
    is       => 'ro',
    required => 1
);

=head2 getProductDetail($product_id)

 Get a plenigo managed product specified by the product id.

=cut

sub getProductDetail {
    my ($self, $product_id) = @_;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->get('product/' . $product_id);
    if ($result{'response_code'} == 404) {
        plenigo::Ex->throw({ code => 404, message => 'There is no product for the product id passed.' });
    }
    else {
        return %{$result{'response_content'}};
    }
}

=head2 getAllProducts()

 Get all plenigo managed products

=cut

sub getAllProducts {
    my ($self, $page, $size) = @_;
    $page //= 0;
    $size //= 10;

    my $rest_client = plenigo::RestClient->new(configuration => $self->configuration);
    my %result = $rest_client->get('products/search/full', { size => $size, page => $page });
    return %{$result{'response_content'}};
}

1;
