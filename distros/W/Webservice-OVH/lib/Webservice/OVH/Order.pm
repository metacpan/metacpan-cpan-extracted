package Webservice::OVH::Order;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $carts = $ovh->order->carts;
    my $cart_id = $carts->[0]->id;
    my $cart = $ovh->order->cart($cart_id);
    
    my $new_cart = $ovh->order->new_cart(ovh_subsidiary => 'DE');
    
    $ovh->order->hosting->web;
    $ovh->order->email->domain;
    $ovh->order->domain->zone;

=head1 DESCRIPTION

Module that support carts and domain/transfer orders at the moment

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.3;

# sub modules
use Webservice::OVH::Order::Cart;
use Webservice::OVH::Order::Hosting;
use Webservice::OVH::Order::Email;
use Webservice::OVH::Order::Domain;

=head2 _new

Internal Method to create the order object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Order>

=item * Synopsis: Webservice::OVH::Order->_new($ovh_api_wrapper, $self);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $hosting = Webservice::OVH::Order::Hosting->_new( wrapper => $api_wrapper, module => $module );
    my $email = Webservice::OVH::Order::Email->_new( wrapper => $api_wrapper, module => $module );
    my $domain = Webservice::OVH::Order::Domain->_new( wrapper => $api_wrapper, module => $module );

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _cards => {}, _hosting => $hosting, _email => $email, _domain => $domain }, $class;

    return $self;
}

=head2 new_cart

Creates a new 'shopping' cart.
Items can be put into it, to create orders. 

=over

=item * Parameter: %params - key => value (required) ovh_subsidiary => 'DE' (optional) expire => DateTime-str description => "shopping" 

=item * Return: L<Webservice::OVH::Order::Cart>

=item * Synopsis: my $cart = $ovh->order->new_cart(ovh_subsidiary => 'DE');

=back

=cut

sub new_cart {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my $cart = Webservice::OVH::Order::Cart->_new( wrapper => $api, module => $self->{_module}, %params );
    return $cart;
}

=head2 carts

Produces an array of all available carts that are connected to the used account.

=over

=item * Return: ARRAY

=item * Synopsis: my $carts = $ovh->order->carts();

=back

=cut

sub carts {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/order/cart", noSignature => 0 );
    croak $response->error if $response->error;

    my $card_ids = $response->content;
    my $cards    = [];

    foreach my $card_id (@$card_ids) {

        my $card = $self->{_cards}{$card_id} = $self->{_cards}{$card_id} || Webservice::OVH::Order::Cart->_new_existing( wrapper => $api, id => $card_id, module => $self->{_module} );
        push @$cards, $card;
    }

    return $cards;
}

=head2 cart

Returns a single cart by id

=over

=item * Parameter: cart_id - cart id

=item * Return: L<Webservice::OVH::Order::Cart>

=item * Synopsis: my $cart = $ovh->order->cart(1234567);

=back

=cut

sub cart {

    my ( $self, $card_id ) = @_;

    my $api             = $self->{_api_wrapper};
    my $from_array_card = $self->{_cards}{$card_id} if $self->{_cards}{$card_id} && $self->{_cards}{$card_id}->is_valid;
    my $card            = $self->{_cards}{$card_id} = $from_array_card || Webservice::OVH::Order::Cart->_new_existing( wrapper => $api, id => $card_id, module => $self->{_module} );
    return $card;
}

=head2 hosting

Gives Acces to the /order/hosting/ methods of the ovh api

=over

=item * Return: L<Webservice::OVH::Order::Hosting>

=item * Synopsis: $ovh->order->hosting

=back

=cut

sub hosting {

    my ($self) = @_;

    return $self->{_hosting};
}

=head2 email

Gives Acces to the /order/email/ methods of the ovh api

=over

=item * Return: L<Webservice::OVH::Order::Email>

=item * Synopsis: $ovh->order->email

=back

=cut

sub email {

    my ($self) = @_;

    return $self->{_email};
}

=head2 domain

Gives Acces to the /order/domain/ methods of the ovh api

=over

=item * Return: L<Webservice::OVH::Order::Domain>

=item * Synopsis: $ovh->order->domain

=back

=cut

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

1;
