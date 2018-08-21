package plenigo::Product;

=head1 NAME

 plenigo::Product - A product used during a checkout. 

=head1 SYNOPSIS

 use plenigo::Product;

 # Create a plenigo product 

 # Initialize a plenigo managed product.

 my $product = plenigo::Product->createPlenigoProduct('PRODUCT_ID');

 # Create a customized product that is not managed within plenigo.

 $product = plenigo::Product->createCustomProduct('PRODUCT_ID', 'TITLE', 'NEWSPAPER', 12.99, 'EUR');

 # Use a plenigo product but add a own product id and a custom title.

 $product = plenigo::Product->createModifiedPlenigoProduct('PRODUCT_ID', 'PRODUCT_ID_NEW', 'TITLE');

=head1 DESCRIPTION

 plenigo::Product represents a product during the checkout.

=cut

use Moo;
use Carp qw(confess);
use Carp::Always;

our $VERSION = '2.0003';

has product_id => (
    is       => 'rw',
    required => 1
);

has price => (
    is => 'rw'
);

has currency => (
    is => 'rw'
);

has type => (
    is => 'rw'
);

has title => (
    is => 'rw'
);

has segment_id => (
    is => 'rw'
);

has oauth2_redirect_url => (
    is => 'rw'
);

has csrf_token => (
    is => 'rw'
);

has category_id => (
    is => 'rw'
);

has pay_what_you_want => (
    is => 'rw'
);

has subscription_renewal => (
    is => 'rw'
);

has shipping_cost => (
    is => 'rw'
);

has override_mode => (
    is      => 'rw',
    default => 0
);

has product_id_replacement => (
    is => 'rw'
);

sub createCheckoutData {
    my ($self, $configuration) = @_;

    my %checkout_data = ('pi' => $self->product_id);

    if ($configuration->staging == 1) {
        $checkout_data{'ts'} = 'true';
    }
    else {
        $checkout_data{'ts'} = 'false';
    }

    if (defined $self->title) {
        $checkout_data{'ti'} = $self->title;
    }

    if (defined $self->type) {
        $checkout_data{'pt'} = $self->type;
    }

    if (defined $self->price) {
        $checkout_data{'pr'} = $self->price;
    }

    if (defined $self->currency) {
        $checkout_data{'cu'} = $self->currency;
    }

    if (defined $self->product_id_replacement) {
        $checkout_data{'pir'} = $self->product_id_replacement;
    }

    if ($self->override_mode == 1) {
        $checkout_data{'om'} = 'true';
    }
    else {
        $checkout_data{'om'} = 'false';
    }

    return %checkout_data;
}

1;

=head2 createPlenigoProduct($product_id)

 Initialize a plenigo managed product.

=cut

sub createPlenigoProduct {
    my ($self, $product_id) = @_;

    my $new_product = plenigo::Product->new(product_id => $product_id);
    return $new_product;
}

=head2 createCustomProduct($product_id, $title, $type, $price, $currency)

 Create a customized product that is not managed within plenigo.

=cut

sub createCustomProduct {
    my ($self, $product_id, $title, $type, $price, $currency) = @_;

    my $new_product = plenigo::Product->new(product_id => $product_id);
    $new_product->title($title);
    $new_product->type($type);
    $new_product->price($price);
    $new_product->currency($currency);
    return $new_product;
}

=head2 createModifiedPlenigoProduct($product_id, $new_product_id, $title)

 Use a plenigo product but add a own product id and a custom title.

=cut

sub createModifiedPlenigoProduct {
    my ($self, $product_id, $new_product_id, $title) = @_;

    my $new_product = plenigo::Product->new(product_id => $product_id);
    $new_product->title($title);
    $new_product->product_id_replacement($new_product_id);
    $new_product->override_mode(1);
    return $new_product;
}
