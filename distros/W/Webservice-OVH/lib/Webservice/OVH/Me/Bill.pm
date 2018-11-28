package Webservice::OVH::Me::Bill;

=encoding utf-8

=head1 NAME

Webservice::OVH::Me::Bill

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $bills = $ovh->me->bills;
    
    foreach my $bill (@$bills) {
        
        print $contact->url;
    }

=head1 DESCRIPTION

Propvides access to contact properties.
No managing methods are available at the moment.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.42;

use Webservice::OVH::Me::Order;

=head2 _new

Internal Method to create the Bill object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $bill_id - api id

=item * Return: L<Webservice::OVH::Me::Bill>

=item * Synopsis: Webservice::OVH::Me::Bill->_new($ovh_api_wrapper, $bill_id, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;
    
    die "Missing module"    unless $params{module};
    die "Missing wrapper"   unless $params{wrapper};
    die "Missing id"        unless $params{id};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $bill_id     = $params{id};

    my $response = $api_wrapper->rawCall( method => 'get', path => "/me/bill/$bill_id", noSignature => 0 );
    croak $response->error if $response->error;

    my $porperties = $response->content;
    my $order_id   = $porperties->{orderId};

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _id => $bill_id, _properties => $porperties, _order_id => $order_id }, $class;

    return $self;
}

=head2 id

Returns the api id.

=over

=item * Return: VALUE

=item * Synopsis: my $id = $bill->id;

=back

=cut

sub id {

    my ($self) = @_;

    return $self->{_id};
}

=head2 order

Returns associated order.

=over

=item * Return: L<Webservice::Me::Order>

=item * Synopsis: my $order = $bill->order;

=back

=cut

sub order {

    my ( $self, $module ) = @_;

    my $api = $self->{_api_wrapper};

    my $order_id = $self->{_order_id};
    my $order    = $module->me->order($order_id);
    return $order;

}

=head2 properties

Retrieves properties.
This method updates the intern property variable.

=over

=item * Return: HASH

=item * Synopsis: my $properties = $bill->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $bill_id  = $self->id;
    my $response = $api->rawCall( method => 'get', path => "/me/bill/$bill_id", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_properties} = $response->content;
    return $self->{_properties};
}

=head2 date

Exposed property value. 

=over

=item * Return: DateTime

=item * Synopsis: my $date = $bill->date;

=back

=cut

sub date {

    my ($self) = @_;

    my $str_datetime = $self->{_properties}->{date};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 password

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $password = $bill->password;

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

=item * Synopsis: my $pdf_url = $bill->pdf_url;

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

=item * Synopsis: my $price_without_tax = $bill->price_without_tax;

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

=item * Synopsis: my $price_with_tax = $bill->price_with_tax;

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

=item * Synopsis: my $tax = $bill->tax;

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

=item * Synopsis: my $url = $bill->url;

=back

=cut

sub url {

    my ($self) = @_;

    return $self->{_properties}->{url};
}

1;
