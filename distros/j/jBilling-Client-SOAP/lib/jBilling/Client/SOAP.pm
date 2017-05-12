package jBilling::Client::SOAP;

use 5.010;
use strict;
use warnings FATAL => 'all';
use jBilling::Client::SOAP::API;
use jBilling::Client::SOAP::OrderWS;
use jBilling::Client::SOAP::OrderLineWS;
use jBilling::Client::SOAP::MetaFieldValueWS;
use jBilling::Client::SOAP::ItemDTOEx;
use jBilling::Client::SOAP::ItemTypeWS;
use jBilling::Client::SOAP::PriceModelWS;
use jBilling::Client::SOAP::Exception;
use Scalar::Util qw(looks_like_number);

our $VERSION = 0.06;
my $API;

sub getAPI {

    # Expects a hash containing URL, Username and Password
    my $self = shift;
    my %args = @_;
    $self->{'API'} = jBilling::Client::SOAP::API->new(%args);

}

sub new {
    my $class = shift;
    my $self  = {};
    bless( $self, $class );
    return $self;
}

sub createOrder {
    my $self    = shift;
    my $orderWS = shift;

    # Pass the Order through to the API
    my $response = $self->{'API'}->createOrder( SOAP::Data->value($orderWS) );
    return $response->valueof('//return');

}

sub createUpdateOrder {
    my $self    = shift;
    my $orderWS = shift;

    # Pass the Order through to the API
    my $response =
      $self->{'API'}->createUpdateOrder( SOAP::Data->value($orderWS) );
    return $response->valueof('//return');

}

sub getOrder {
    my $self    = shift;
    my $orderId = shift;
    my $response =
      $self->{'API'}->getOrder(
        SOAP::Data->new( name => 'arg0', value => $orderId, type => 'xsd:int' )
      );

    my $order = jBilling::Client::SOAP::OrderWS->new();

    # Populate a new OrderWS Object
    $order->load( $response->valueof('//return') );
    return $order;
}

sub getAllItems {
    my $self = shift;
    my @items;

    my $response = $self->{'API'}->getAllItems();
    print $response->valueof('//return');
}

sub getItemByCategory {
    my $self    = shift;
    my $type_id = shift;
    my @items;

    my $response =
      $self->{'API'}->getItemByCategory(
        SOAP::Data->new( name => 'arg0', value => $type_id, type => 'xsd:int' )
      );
    my @returned = $response->valueof('//return');
    foreach (@returned) {
        my $itemDTOEx = jBilling::Client::SOAP::ItemDTOEx->new();
        $itemDTOEx->load( \%{$_} );
        push @items, $itemDTOEx;
    }
    return @items;
}

sub updateOrderLine {
    my $self = shift;
    my @data = @_;

    my $response =
      $self->{'API'}
      ->updateOrderLine( SOAP::Data->new( name => 'arg0', value => \@data ) );
}

1;

=pod

=head1 NAME

jBilling::Client::SOAP - Communicate with jBilling

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

This module acts as an interface for functionality exposed by the
jBilling SOAP API.  

=head2 Initialise the library

C<< use jBilling::Client::SOAP;
	my $jb = jBilling::Client::SOAP->new();
	$jb->getAPI(
	'username' => 'yourusername',
	'password' => 'yourpassword',
	'url'      => 'http://yourservername:yourserverport/jbilling/services/api'
	);    # Initialise the API 
>>

=head1 EXAMPLES

L<Retrieve an Order|https://bitbucket.org/guisea/jbilling-client-soap/src/c566a04ce73c78c52e5986873b899a5373730263/examples/RetrieveOrder.pl?at=master>

L<Create a new order|https://bitbucket.org/guisea/jbilling-client-soap/src/c566a04ce73c78c52e5986873b899a5373730263/examples/CreateOrder.pl?at=master>

=head1 SUBROUTINES/METHODS

=head2 getAPI

This method initiates a SOAP::Lite object for later re-use

=head2 new

Constructs the jBilling::Client::SOAP object

=cut
