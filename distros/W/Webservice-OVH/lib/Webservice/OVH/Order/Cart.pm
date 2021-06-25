package Webservice::OVH::Order::Cart;

=encoding utf-8

=head1 NAME

Webservice::OVH::Order::Cart

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $cart = $ovh->order->new_cart(ovh_subsidiary => 'DE');
    
    $cart->add_domain('www.domain.com');
    
    $cart->delete;

=head1 DESCRIPTION

Provides methods to manage shopping carts.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.46;

use Webservice::OVH::Order::Cart::Item;

=head2 _new_existing

Internal Method to create the Cart object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $cart_id - api id

=item * Return: L<Webservice::OVH::Order::Cart>

=item * Synopsis: Webservice::OVH::Order::Cart->_new($ovh_api_wrapper, $cart_id, $module);

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $cart_id     = $params{id};

    my $response = $api_wrapper->rawCall( method => 'get', path => "/order/cart/$cart_id", noSignature => 0 );
    carp $response->error if $response->error;

    if ( !$response->error ) {

        my $properties = $response->content;
        my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $cart_id, _properties => $properties, _items => {} }, $class;

        return $self;

    } else {

        return undef;
    }
}

=head2 _new_existing

Internal Method to create the Cart object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object - api id

=item * Return: L<Webservice::OVH::Order::Cart>

=item * Synopsis: Webservice::OVH::Order::Cart->_new($ovh_api_wrapper, $module, ovhSubsidiary => 'DE', decription => 'Shopping');

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    croak "Missing ovh_subsidiary" unless exists $params{ovh_subsidiary};
    my $body = {};
    $body->{description} = $params{description} if exists $params{description};
    $body->{expire}      = $params{expire}      if exists $params{expire};
    $body->{ovhSubsidiary} = $params{ovh_subsidiary};
    my $response = $api_wrapper->rawCall( method => 'post', path => "/order/cart", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $cart_id    = $response->content->{cartId};
    my $properties = $response->content;

    my $response_assign = $api_wrapper->rawCall( method => 'post', path => "/order/cart/$cart_id/assign", body => {}, noSignature => 0 );
    croak $response_assign->error if $response_assign->error;

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _id => $cart_id, _properties => $properties, _items => {} }, $class;

    return $self;
}

=head2 properties

Retrieves properties.
This method updates the intern property variable.

=over

=item * Return: HASH

=item * Synopsis: my $properties = $cart->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $cart_id  = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/order/cart/$cart_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 description

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $description = $cart->description;

=back

=cut

sub description {

    my ($self) = @_;

    return $self->{_properties}->{description};
}

=head2 expire

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $expire = $cart->expire;

=back

=cut

sub expire {

    my ($self) = @_;

    return $self->{_properties}->{expire};
}

=head2 read_only

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $read_only = $cart->read_only;

=back

=cut

sub read_only {

    my ($self) = @_;

    return $self->{_properties}->{readOnly} ? 1 : 0;
}

=head2 change

Exposed property value. 

=over

=item * Parameter: %params - key => value description expire

=item * Synopsis: my $change = $cart->change(description => 'Shopping!');

=back

=cut

sub change {

    my ( $self, %params ) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    croak "Missing Parameter description" unless exists $params{description};
    croak "Missing Parameter description" unless exists $params{expire};

    my $body = {};
    $body->{description} = $params{description} if $params{description};
    $body->{expire}      = $params{expire}      if $params{expire};

    my $response = $api->rawCall( method => 'put', path => "/order/cart/$cart_id", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    $self->properties;
}

=head2 is_valid

When this cart is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $cart->is_valid;

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

=item * Synopsis: $cart->_is_valid;

=back

=cut

sub _is_valid {

    my ($self) = @_;

    my $cart_id = $self->id;
    carp "Cart $cart_id is not valid anymore" unless $self->is_valid;
    return $self->is_valid;
}

=head2 delete

Deletes the cart api sided and sets this object invalid.

=over

=item * Synopsis: $cart->delete;

=back

=cut

sub delete {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    my $response = $api->rawCall( method => 'delete', path => "/order/cart/$cart_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_valid} = 0;
}

=head2 id

Returns the api id.

=over

=item * Return: VALUE

=item * Synopsis: my $id = $cart->id;

=back

=cut

sub id {

    my ($self) = @_;

    return $self->{_id},;
}

=head2 offers_domain

Returns an Array of hashs with offers.

=over

=item * Parameter: $domain - domain name

=item * Return: L<ARRAY>

=item * Synopsis: my $offers = $cart->offers_domain('mydomain.de');

=back

=cut

sub offers_domain {

    my ( $self, $domain ) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    my $response = $api->rawCall( method => 'get', path => sprintf( "/order/cart/%s/domain?domain=%s", $cart_id, $domain ), noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 add_domain

Adds a domain request to a cart.

=over

=item * Parameter: $domain - domain name, %params - key => value duration offer_id quantity

=item * Return: L<Webservice::OVH::Order::Cart::Item>

=item * Synopsis: my $item = $cart->add_domain('mydomain.de');

=back

=cut

sub add_domain {

    my ( $self, $domain, %params ) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    croak "Missing domain parameter" unless $domain;

    my $body = {};
    $body->{duration} = $params{duration} if exists $params{duration};
    $body->{offerId}  = $params{offer_id} if exists $params{offer_id};
    $body->{quantity} = $params{quantity} if exists $params{quantity};
    $body->{domain}   = $domain;

    my $response = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/domain", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $item_id = $response->content->{itemId};
    my $item = Webservice::OVH::Order::Cart::Item->_new( wrapper => $api, cart => $self, id => $item_id, module => $self->{_module} );

    my $owner = $params{owner_contact};
    my $admin = $params{admin_account};
    my $tech  = $params{tech_account};

    if ($owner) {
        my $config_preset_owner = { label => "OWNER_CONTACT", value => $owner };
        my $response_product_set_config_owner = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/item/$item_id/configuration", body => $config_preset_owner, noSignature => 0 );
        my $config2 = $response_product_set_config_owner->content unless $response_product_set_config_owner->error;
        croak $response_product_set_config_owner->error if $response_product_set_config_owner->error;
    }

    if ($admin) {

        my $config_preset_admin = { label => "ADMIN_ACCOUNT", value => $admin };
        my $response_product_set_config_admin = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/item/$item_id/configuration", body => $config_preset_admin, noSignature => 0 );
        my $config3 = $response_product_set_config_admin->content unless $response_product_set_config_admin->error;
        croak $response_product_set_config_admin->error if $response_product_set_config_admin->error;
    }

    if ($tech) {

        my $config_preset_tech = { label => "TECH_ACCOUNT", value => $tech };
        my $response_product_set_config_tech = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/item/$item_id/configuration", body => $config_preset_tech, noSignature => 0 );
        my $config4 = $response_product_set_config_tech->content unless $response_product_set_config_tech->error;
        croak $response_product_set_config_tech->error if $response_product_set_config_tech->error;
    }

    return $item;
}

=head2 offer_dns

Returns an Hash with information for dns Zone pricing
A Domain must be added before requestion info

=over

=item * Parameter: $dns - domain name

=item * Return: L<HASHREF>

=item * Synopsis: my $offer = $cart->offers_dns;

=back

=cut

sub offer_dns {

    my ( $self, $domain ) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    my $response = $api->rawCall( method => 'get', path => sprintf( "/order/cart/%s/dns?domain=%s", $cart_id, $domain ), noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 add_dns

Adds a dns Zone to a cart.

=over

=item * Return: L<Webservice::OVH::Order::Cart::Item>

=item * Synopsis: my $item = $cart->add_dns;

=back

=cut

sub add_dns {

    my ( $self, $domain, %params ) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    my $body = {};
    $body->{duration} = $params{duration} if exists $params{duration};
    $body->{planCode} = $params{plan_code} if exists $params{plan_code};
    $body->{pricingMode} = $params{pricing_mode} if exists $params{pricing_mode};
    $body->{quantity} = $params{quantity} if exists $params{quantity};
    $body->{domain}   = $domain;

    my $response = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/dns", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $item_id = $response->content->{itemId};
    my $item = Webservice::OVH::Order::Cart::Item->_new( wrapper => $api, cart => $self, id => $item_id, module => $self->{_module} );

    return $item;
}


=head2 offers_domain_transfer

Returns an Array of hashes with offers.

=over

=item * Parameter: $domain - domain name

=item * Return: L<ARRAY>

=item * Synopsis: my $offers = $cart->offers_domain_transfer('mydomain.de');

=back

=cut

sub offers_domain_transfer {

    my ( $self, $domain ) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    my $response = $api->rawCall( method => 'get', path => sprintf( "/order/cart/%s/domainTransfer?domain=%s", $cart_id, $domain ), noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 offers_domain

Adds a domain transfer request to a cart.

=over

=item * Parameter: $domain - domain name, %params - key => value duration offer_id quantity

=item * Return: L<Webservice::OVH::Order::Cart::Item>

=item * Synopsis: my $item = $cart->add_transfer('mydomain.de');

=back

=cut

sub add_transfer {

    my ( $self, $domain, %params ) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    croak "Missing domain parameter" unless $domain;
    croak "Missing auth_info" unless exists $params{auth_info};

    my $body = {};
    $body->{duration} = $params{duration} if exists $params{duration};
    $body->{offerId}  = $params{offer_id} if exists $params{offer_id};
    $body->{quantity} = $params{quantity} if exists $params{quantity};
    $body->{domain}   = $domain;

    my $response = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/domainTransfer", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $item_id = $response->content->{itemId};
    my $item = Webservice::OVH::Order::Cart::Item->_new( wrapper => $api, cart => $self, id => $item_id, module => $self->{_module} );

    return unless $item;

    my $auth_info = $params{auth_info};
    my $owner     = $params{owner_contact};
    my $admin     = $params{admin_account};
    my $tech      = $params{tech_account};

    my $config_preset = { label => "AUTH_INFO", value => $auth_info };
    my $response_product_set_config = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/item/$item_id/configuration", body => $config_preset, noSignature => 0 );
    my $config1 = $response_product_set_config->content unless $response_product_set_config->error;
    croak $response_product_set_config->error if $response_product_set_config->error;

    if ($owner) {
        my $config_preset_owner = { label => "OWNER_CONTACT", value => $owner };
        my $response_product_set_config_owner = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/item/$item_id/configuration", body => $config_preset_owner, noSignature => 0 );
        my $config2 = $response_product_set_config_owner->content unless $response_product_set_config_owner->error;
        croak $response_product_set_config_owner->error if $response_product_set_config_owner->error;
    }

    if ($admin) {
        my $config_preset_admin = { label => "ADMIN_ACCOUNT", value => $admin };
        my $response_product_set_config_admin = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/item/$item_id/configuration", body => $config_preset_admin, noSignature => 0 );
        my $config3 = $response_product_set_config_admin->content unless $response_product_set_config_admin->error;
        croak $response_product_set_config_admin->error if $response_product_set_config_admin->error;
    }

    if ($tech) {
        my $config_preset_tech = { label => "TECH_ACCOUNT", value => $tech };
        my $response_product_set_config_tech = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/item/$item_id/configuration", body => $config_preset_tech, noSignature => 0 );
        my $config4 = $response_product_set_config_tech->content unless $response_product_set_config_tech->error;
        croak $response_product_set_config_tech->error if $response_product_set_config_tech->error;
    }

    return $item;
}

=head2 info_checkout

Returns checkout without generating an order.

=over

=item * Return: HASH

=item * Synopsis: my $checkout = $cart->info_checkout;

=back

=cut

sub info_checkout {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    my $response = $api->rawCall( method => 'get', path => "/order/cart/$cart_id/checkout", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 checkout

Generates an order. Makes the cart invalid. Returns the order.

=over

=item * Return: L<Webservice::OVH::Me::Order>

=item * Synopsis: my $order = $cart->checkout;

=back

=cut

sub checkout {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api     = $self->{_api_wrapper};
    my $cart_id = $self->id;

    my $response = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/checkout", body => {}, noSignature => 0 );
    croak $response->error if $response->error;

    my $order_id = $response->content->{orderId};
    my $order = Webservice::OVH::Me::Order->_new( wrapper => $api, id => $order_id, module => $self->{_module} );

    return $order;
}

=head2 items

Produces an Array of Item Objects. 

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $items = $cart->items;

=back

=cut

sub items {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api      = $self->{_api_wrapper};
    my $cart_id  = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/order/cart/$cart_id/item", noSignature => 0 );
    croak $response->error if $response->error;

    my $item_ids = $response->content;
    my $items    = [];

    foreach my $item_id (@$item_ids) {

        my $item = $self->{_items}{$item_id} = $self->{_items}{$item_id} || Webservice::OVH::Order::Cart::Item->_new( wrapper => $api, cart => $self, id => $item_id, module => $self->{_module} );
        push @$items, $item;
    }

    return $items;
}

=head2 item

Returns a single item by id

=over

=item * Parameter: $item_id - api id

=item * Return: L<Webservice::OVH::Order::Cart::Item>

=item * Synopsis: my $item = $ovh->order->cart->item(123456);

=back

=cut

sub item {

    my ( $self, $item_id ) = @_;

    return unless $self->_is_valid;

    my $api = $self->{_api_wrapper};
    my $item = $self->{_items}{$item_id} = $self->{_items}{$item_id} || Webservice::OVH::Order::Cart::Item->_new( wrapper => $api, cart => $self, id => $item_id, module => $self->{_module} );
    return $item;
}

=head2 item

Deletes all items from the cart.

=over

=item * Synopsis: $cart->clear;

=back

=cut

sub clear {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $items = $self->items;

    foreach my $item (@$items) {

        $item->delete;
    }
}

=head2 assign

Assign a shopping cart to an loggedin client

=over

=item * Synopsis: $cart->assign;

=back

=cut

sub assign {

    my ($self) = @_;

    return unless $self->_is_valid;

    my $api      = $self->{_api_wrapper};
    my $cart_id  = $self->id;
    my $response = $api->rawCall( method => 'post', path => "/order/cart/$cart_id/assign", noSignature => 0 );
    croak $response->error if $response->error;
}






1;

