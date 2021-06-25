package Webservice::OVH::Me::Order::Detail;

=encoding utf-8

=head1 NAME

Webservice::OVH::Me::Order::Details

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $order = $ovh->me->orders->[0];
    
    my $details = $order->details;
    
    foreach my $detail (@$details) {
        
        print $detail->unit_price;
    }

=head1 DESCRIPTION

Provides access to details for an order entry.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.46;

=head2 _new

Internal Method to create the Detail object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $detail_id - api id

=item * Return: L<Webservice::OVH::Me::Order::Detail>

=item * Synopsis: Webservice::OVH::Me::Order::Detail->_new($ovh_api_wrapper, $detail_id, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"    unless $params{module};
    die "Missing wrapper"   unless $params{wrapper};
    die "Missing id"        unless $params{id};
    die "Missing order"     unless $params{order};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $detail_id     = $params{id};
    my $order       = $params{order};
    my $order_id = $order->id;

    my $response = $api_wrapper->rawCall( method => 'get', path => "/me/order/$order_id/details/$detail_id", noSignature => 0 );
    croak $response->error if $response->error;

    my $porperties = $response->content;

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _id => $detail_id, _properties => $porperties, _order => $order }, $class;

    return $self;
}

=head2 order

Returns root Order object.

=over

=item * Return: L<Webservice::OVH::Me::Order>

=item * Synopsis: my $order = $datail->order;

=back

=cut

sub order {

    my ($self) = @_;

    return $self->{_order};
}

=head2 id

Returns the api id.

=over

=item * Return: VALUE

=item * Synopsis: my $id = $detail->id;

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

=item * Synopsis: my $properties = $detail->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api       = $self->{_api_wrapper};
    my $order_id  = $self->{_order}->id;
    my $detail_id = $self->id;
    my $response  = $api->rawCall( method => 'get', path => "/me/order/$order_id/details/$detail_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 description

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $description = $detail->description;

=back

=cut

sub description {

    my ($self) = @_;

    return $self->{_properties}->{description};
}

=head2 domain

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $domain = $detail->domain;

=back

=cut

sub domain {

    my ($self) = @_;

    return $self->{_properties}->{domain};
}

=head2 quantity

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $quantity = $detail->quantity;

=back

=cut

sub quantity {

    my ($self) = @_;

    return $self->{_properties}->{quantity};
}

=head2 total_price

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $total_price = $detail->total_price;

=back

=cut

sub total_price {

    my ($self) = @_;

    return $self->{_properties}->{totalPrice};
}

=head2 unit_price

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $unit_price = $detail->unit_price;

=back

=cut

sub unit_price {

    my ($self) = @_;

    return $self->{_properties}->{unitPrice};
}

1;
