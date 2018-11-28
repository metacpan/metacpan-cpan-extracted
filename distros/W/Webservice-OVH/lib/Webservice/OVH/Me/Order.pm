package Webservice::OVH::Me::Order;

=encoding utf-8

=head1 NAME

Webservice::OVH::Me::Order

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $order = $ovh->me->order(1234);
    
    my $order->pay_with_registered_payment_mean('fiedelityAccount')

=head1 DESCRIPTION

Module provides possibility to access specified orders and payment options.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.42;

use Webservice::OVH::Me::Order::Detail;

=head2 _new

Internal Method to create the Order object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $order_id - api id

=item * Return: L<Webservice::OVH::Me::Order>

=item * Synopsis: Webservice::OVH::Me::Order->_new($ovh_api_wrapper, $order_id, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"    unless $params{module};
    die "Missing wrapper"   unless $params{wrapper};
    die "Missing id"        unless $params{id};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $order_id     = $params{id};

    my $response = $api_wrapper->rawCall( method => 'get', path => "/me/order/$order_id", noSignature => 0 );
    croak $response->error if $response->error;

    my $porperties = $response->content;

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _id => $order_id, _properties => $porperties, _details => {} }, $class;

    return $self;
}

=head2 id

Returns the api id.

=over

=item * Return: VALUE

=item * Synopsis: my $id = $order->id;

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

=item * Synopsis: my $properties = $order->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/me/order/$order_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 date

Exposed property value. 

=over

=item * Return: DateTime

=item * Synopsis: my $date = $order->is_blocked;

=back

=cut

sub date {

    my ($self) = @_;

    my $str_datetime = $self->{_properties}->{date};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 expiration_date

Exposed property value. 

=over

=item * Return: DateTime

=item * Synopsis: my $expiration_date = $order->expiration_date;

=back

=cut

sub expiration_date {

    my ($self) = @_;

    my $str_datetime = $self->{_properties}->{expirationDate};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 password

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $password = $order->password;

=back

=cut

sub password {

    my ($self) = @_;

    return $self->{_properties}->{password};
}

=head2 pdf_url

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $pdf_url = $order->pdf_url;

=back

=cut

sub pdf_url {

    my ($self) = @_;

    return $self->{_properties}->{pdfUrl};
}

=head2 price_without_tax

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $price_without_tax = $order->price_without_tax;

=back

=cut

sub price_without_tax {

    my ($self) = @_;

    return $self->{_properties}->{priceWithoutTax};
}

=head2 price_with_tax

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $price_with_tax = $order->price_with_tax;

=back

=cut

sub price_with_tax {

    my ($self) = @_;

    return $self->{_properties}->{priceWithTax};
}

=head2 tax

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $tax = $order->tax;

=back

=cut

sub tax {

    my ($self) = @_;

    return $self->{_properties}->{tax};
}

=head2 url

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $url = $order->url;

=back

=cut

sub url {

    my ($self) = @_;

    return $self->{_properties}->{url};
}

=head2 associated_object

Exposed property value. 

=over

=item * Return: HASH

=item * Synopsis: my $associated_object = $order->associated_object;

=back

=cut

sub associated_object {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/me/order/$order_id/associatedObject", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 available_registered_payment_mean

Returns an Array of available payment means.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $available_registered_payment_mean = $order->available_registered_payment_mean;

=back

=cut

sub available_registered_payment_mean {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/me/order/$order_id/availableRegisteredPaymentMean", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 bill

Returns associated bill.

=over

=item * Return: L<Webservice::Me::Bill>

=item * Synopsis: my $bill = $order->bill;

=back

=cut

sub bill {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $module   = $self->{_module};

    #my $response = $api->rawCall( method => 'get', path => "/me/order/$order_id/bill", noSignature => 0 );
    #croak $response->error if $response->error;

    my $object = $self->associated_object;

    if ( $object->{type} eq 'Bill' ) {

        my $bill = $module->me->bill( $object->{id} );

        return $bill;
    } else {

        return undef;
    }
}

=head2 details

Returns an Array of detail Objects.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $details = $order->details;

=back

=cut

sub details {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/me/order/$order_id/details", noSignature => 0 );
    croak $response->error if $response->error;

    my $detail_ids = $response->content;
    my $details    = [];

    foreach my $detail_id (@$detail_ids) {

        my $detail = $self->{_details}{$detail_id} = $self->{_details}{$detail_id} || Webservice::OVH::Me::Order::Detail->_new( wrapper => $api, order => $self, id => $detail_id, module => $self->{_module} );
        push @$details, $detail;
    }

    return $details;
}

=head2 details

Gets a specified detail Object by id.

=over

=item * Return: L<Webservice::Me::Order::Detail>

=item * Synopsis: my $details = $order->details;

=back

=cut

sub detail {

    my ( $self, $detail_id ) = @_;

    my $api = $self->{_api_wrapper};
    my $detail = $self->{_details}{$detail_id} = $self->{_details}{$detail_id} || Webservice::OVH::Me::Order::Detail->_new( wrapper => $api, order => $self, id => $detail_id, module => $self->{_module} );

    return $detail;
}

=head2 payment

Gets details about payment.

=over

=item * Return: VALUE

=item * Synopsis: my $payment = $order->payment;

=back

=cut

sub payment {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/me/order/$order_id/payment", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 payment_means

Gets details about payment_means.

=over

=item * Return: VALUE

=item * Synopsis: my $payment_means = $order->payment_means;

=back

=cut

sub payment_means {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/me/order/$order_id/paymentMeans", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 pay_with_registered_payment_mean

Pays the order.

=over

=item * Parameter: $payment_mean - payment mean

=item * Synopsis: $order->pay_with_registered_payment_mean;

=back

=cut

sub pay_with_registered_payment_mean {

    my ( $self, $payment_mean ) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $response = $api->rawCall( method => 'post', path => "/me/order/$order_id/payWithRegisteredPaymentMean", body => { paymentMean => $payment_mean }, noSignature => 0 );
    croak $response->error if $response->error;
}

=head2 status

Status of the order.

=over

=item * Return: VALUE

=item * Synopsis: my $status = $order->status;

=back

=cut

sub status {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $order_id = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/me/order/$order_id/status", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

1;
