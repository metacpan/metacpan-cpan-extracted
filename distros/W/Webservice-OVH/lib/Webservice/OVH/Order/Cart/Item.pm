package Webservice::OVH::Order::Cart::Item;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order::Cart::Item

=head1 SYNOPSIS

use Webservice::OVH;

my $ovh = Webservice::OVH->new_from_json("credentials.json");

my $cart = $ovh->order->new_cart(ovh_subsidiary => 'DE');

my $items = $cart->items;

=head1 DESCRIPTION

Provides info for a specific cart item.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.42;

=head2 _new

Internal Method to create the Item object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $item_id - api id

=item * Return: L<Webservice::OVH::Order::Cart>

=item * Synopsis: Webservice::OVH::Order::Cart->_new($ovh_api_wrapper, $cart_id, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};
    die "Missing cart"    unless $params{cart};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $item_id     = $params{id};
    my $cart        = $params{cart};

    my $cart_id = $cart->id;
    my $response = $api_wrapper->rawCall( method => 'get', path => "/order/cart/$cart_id/item/$item_id", noSignature => 0 );
    croak $response->error if $response->error;

    my $porperties = $response->content;

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $item_id, _properties => $porperties, _cart => $cart }, $class;

    return $self;
}

=head2 is_valid

When the item is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $item->is_valid;

=back

=cut

sub is_valid {

    my ($self) = @_;

    return $self->{_valid};
}

=head2 _is_valid

Intern method to check validity.
Difference is that this method carps an error.

=over

=item * Return: VALUE

=item * Synopsis: $item->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    my $item_id = $self->id;
    carp "Item $item_id is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 _is_valid

Gets the associated cart.

=over

=item * Return: L<Webservice::OVH::Order::Cart>

=item * Synopsis: my $cart = $item->cart;

=back

=cut

sub cart {

    my ($self) = @_;

    return $self->{_cart};
}

=head2 id

Returns the api id.

=over

=item * Return: VALUE

=item * Synopsis: my $id = $item->id;

=back

=cut

sub id {

    my ($self) = @_;

    return $self->{_id};
}

=head2 properties

Retrieves properties.
This method updates the intern property variable.

=over

=item * Return: HASH

=item * Synopsis: my $properties = $item->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api      = $self->{_api_wrapper};
    my $cart_id  = $self->{_cart}->id;
    my $item_id  = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/order/cart/$cart_id/item/$item_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 configurations

Exposed property value. 

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $configurations = $item->configurations;

=back

=cut

sub configurations {

    my ($self) = @_;

    return $self->{_properties}->{configurations};
}

=head2 duration

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $duration = $item->duration;

=back

=cut

sub duration {

    my ($self) = @_;

    return $self->{_properties}->{duration};
}

=head2 offer_id

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $offer_id = $item->offer_id;

=back

=cut

sub offer_id {

    my ($self) = @_;

    return $self->{_properties}->{offerId};
}

=head2 options

Exposed property value. 

=over

=item * Return: HASH

=item * Synopsis: my $options = $item->options;

=back

=cut

sub options {

    my ($self) = @_;

    return $self->{_properties}->{options};
}

=head2 prices

Exposed property value. 

=over

=item * Return: HASH

=item * Synopsis: my $prices = $item->prices;

=back

=cut

sub prices {

    my ($self) = @_;

    return $self->{_properties}->{prices};
}

=head2 product_id

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $product_id = $item->product_id;

=back

=cut

sub product_id {

    my ($self) = @_;

    return $self->{_properties}->{productId};
}

=head2 settings

Exposed property value. 

=over

=item * Return: HASH

=item * Synopsis: my $settings = $item->settings;

=back

=cut

sub settings {

    my ($self) = @_;

    return $self->{_properties}->{settings};
}

=head2 available_configuration

Exposed property value. 

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $available_configuration = $item->available_configuration;

=back

=cut

sub available_configuration {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->{_cart}->id;
    my $item_id = $self->id;

    my $response = $api->rawCall( method => 'get', path => "/order/cart/$cart_id/item/$item_id/configuration", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 delete

Deletes the item and sets the object to invalid. 

=over

=item * Synopsis: $item->delete;

=back

=cut

sub delete {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api      = $self->{_api_wrapper};
    my $cart_id  = $self->{_cart}->id;
    my $item_id  = $self->id;
    my $response = $api->rawCall( method => 'delete', path => "/order/cart/$cart_id/item/$item_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_valid} = 0;
}

1;
