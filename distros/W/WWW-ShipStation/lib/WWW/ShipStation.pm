package WWW::ShipStation;

use strict;
use 5.008_005;
our $VERSION = '0.06';

use LWP::UserAgent;
use JSON;
use Carp 'croak';
use URI::Escape qw/uri_escape/;
use HTTP::Request;

sub new {
    my $class = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;

    $args{user} or croak "user is required.";
    $args{pass} or croak "pass is required.";

    $args{ua} ||= LWP::UserAgent->new();
    $args{json} ||= JSON->new->allow_nonref->utf8;

    $args{API_BASE} ||= 'https://ssapi.shipstation.com/';

    bless \%args, $class;
}

sub getCarriers {
    (shift)->request('carriers');
}

sub getCustomer {
    my ($self, $customerId) = @_;
    $self->request("customers/$customerId");
}

sub getCustomers {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    $self->request('customers', %args);
}

sub getOrder {
    my ($self, $orderId) = @_;
    $self->request("orders/$orderId");
}

sub getOrders {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    $self->request('orders', %args);
}

sub getProduct {
    my ($self, $productId) = @_;
    $self->request("products/$productId");
}

sub getProducts {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    $self->request('products/', %args);
}

sub getShipments {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    $self->request('shipments', %args);
}

sub getMarketplaces {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    $self->request('stores/marketplaces', %args);
}

sub getStores {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    $self->request('stores', %args);
}

sub getStore {
    my ($self, $storeId) = @_;
    $self->request("stores/$storeId");
}

sub getWarehouses {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    $self->request('warehouses', %args);
}

sub getWarehouse {
    my ($self, $warehouseId) = @_;
    $self->request("warehouses/$warehouseId");
}

sub request {
    my ($self, $url, %params) = @_;

    if (%params and keys %params) {
        $url .= '?' . join('&', map { join('=', $_, uri_escape($params{$_})) } keys %params);
    }

    my $req = HTTP::Request->new(GET => $self->{API_BASE} . $url);
    $req->authorization_basic($self->{user}, $self->{pass});
    $req->header('Accept', 'application/json'); # JSON is better
    my $res = $self->{ua}->request($req);
    # use Data::Dumper; print STDERR Dumper(\$res);
    if ($res->header('Content-Type') =~ m{application/json}) {
        return $self->{json}->decode($res->decoded_content);
    }
    unless ($res->is_success) {
        return {
            'error' => {
                'code' => '',
                'message' => {
                    'lang' => 'en-US',
                    'value' => $res->status_line,
                }
            }
        };
    }
}

sub createOrder {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    $self->__request('POST', 'orders/createorder', $self->{json}->encode(\%args));
}

sub deleteOrder {
    my ($self, $orderID) = @_;

    $self->__request('DELETE', "orders/$orderID");
}

sub __request {
    my ($self, $method, $url, $content) = @_;

    my $req = HTTP::Request->new($method => $self->{API_BASE} . $url);
    $req->authorization_basic($self->{user}, $self->{pass});
    $req->header('Accept', 'application/json'); # JSON is better
    $req->header('Accept-Charset' => 'UTF-8');
    if ($method eq 'POST') {
        $req->header('Content-Type' => 'application/json');
    }
    $req->content($content) if $content;

    my $res = $self->{ua}->request($req);
    # use Data::Dumper; print STDERR Dumper(\$res);
    if ($res->header('Content-Type') =~ m{application/json}) {
        return $self->{json}->decode($res->decoded_content);
    }
    unless ($res->is_success) {
        return {
            'error' => {
                'code' => '',
                'message' => {
                    'lang' => 'en-US',
                    'value' => $res->status_line
                }
            }
        };
    }
    return $res->decoded_content;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::ShipStation - ShipStation API

=head1 SYNOPSIS

    use WWW::ShipStation;

=head1 DESCRIPTION

WWW::ShipStation is for L<http://www.shipstation.com/developer-api/>

refer examples for running code

=head1 METHODS

=head2 new

    my $ws = WWW::ShipStation->new(
        user => 'blabla',
        pass => 'blabla'
    );

=over 4

=item * user

required, API key

=item * pass

required, API secret

=item * ua

optional, L<LWP::UserAgent> based.

=item * json

optional, L<JSON> based

=back

=head2 getCarriers

    my $carriers = $ws->getCarriers();

L<http://www.shipstation.com/developer-api/#/reference/customers/list-carriers>

=head2 getCustomer

    my $customer = $ws->getCustomer($customer_id);

=head2 getCustomers

    my $customers = $ws->getCustomers();
    my $customers = $ws->getCustomers(
        stateCode => ...
        countryCode => ...
    );

L<http://www.shipstation.com/developer-api/#/reference/customers/list-customers/list-customers>

=head2 getMarketplaces

    my $marketplaces = $ws->getMarketplaces();

L<http://www.shipstation.com/developer-api/#/reference/stores/storesmarketplaces/get>

=head2 getOrders

    my $orders = $ws->getOrders();
    my $orders = $ws->getOrders(
        customerName => ...
        createDateStart => ...
    );

L<http://www.shipstation.com/developer-api/#/reference/orders/orders/get>

=head2 getOrder

    my $order = $ws->getOrder($orderId);

L<http://www.shipstation.com/developer-api/#/reference/orders/order/get-order>

=head2 getProducts

    my $products = $ws->getProducts(
        sku => ...
    );

L<http://www.shipstation.com/developer-api/#/reference/products/products/get>

=head2 getShipments

    my $shipments = $ws->getShipments(
        orderId => ...
    );

L<http://www.shipstation.com/developer-api/#/reference/shipments/shipments/get>

=head2 getStores

    my $stores = $ws->getStores(
        showInactive => 1,
    );

L<http://www.shipstation.com/developer-api/#/reference/stores>

=head2 getWarehouses

    my $warehouses = $ws->getWarehouses();

L<http://www.shipstation.com/developer-api/#/reference/warehouses/warehouses/get>

=head2 createOrder

    my $order = $ws->createOrder({
      "orderNumber" => "TEST-ORDER-API-DOCS",
      "orderKey" => "0f6bec18-3e89-4771-83aa-f392d84f4c74",
      "orderDate" => "2015-06-29T08:46:27.0000000",
      "paymentDate" => "2015-06-29T08:46:27.0000000",
      "orderStatus" => "awaiting_shipment",
      "customerUsername" => 'headhoncho@whitehouse.gov',
      "customerEmail" => 'headhoncho@whitehouse.gov',
      "billTo" => {
        "name" => "The President",
        "company" => undef,
        "street1" => undef,
        "street2" => undef,
        "street3" => undef,
        "city" => undef,
        "state" => undef,
        "postalCode" => undef,
        "country" => undef,
        "phone" => undef,
        "residential" => undef
      },
      "shipTo" => {
        "name" => "The President",
        "company" => "US Govt",
        "street1" => "1600 Pennsylvania Ave",
        "street2" => "Oval Office",
        "street3" => undef,
        "city" => "Washington",
        "state" => "DC",
        "postalCode" => "20500",
        "country" => "US",
        "phone" => "555-555-5555",
        "residential" => 1
      },
      "items" => [
        {
          "lineItemKey" => "vd08-MSLbtx",
          "sku" => "ABC123",
          "name" => "Test item #1",
          "imageUrl" => undef,
          "weight" => {
            "value" => 24,
            "units" => "ounces"
          },
          "quantity" => 2,
          "unitPrice" => 99.99,
          "warehouseLocation" => "Aisle 1, Bin 7",
          "options" => [
            {
              "name" => "Size",
              "value" => "Large"
            }
          ],
          "adjustment" => 0
        },
        {
          "lineItemKey" => undef,
          "sku" => "DISCOUNT CODE",
          "name" => "10% OFF",
          "imageUrl" => undef,
          "weight" => {
            "value" => 0,
            "units" => "ounces"
          },
          "quantity" => 1,
          "unitPrice" => -20.55,
          "warehouseLocation" => undef,
          "options" => [],
          "adjustment" => 1
        }
      ],
      "amountPaid" => 218.73,
      "taxAmount" => 5,
      "shippingAmount" => 10,
      "customerNotes" => "Thanks for ordering!",
      "internalNotes" => "Customer called and would like to upgrade shipping",
      "gift" => 1,
      "giftMessage" => "Thank you!",
      "paymentMethod" => "Credit Card",
      "requestedShippingService" => "Priority Mail",
      "carrierCode" => "fedex",
      "serviceCode" => "fedex_2day",
      "packageCode" => "package",
      "confirmation" => "delivery",
      "shipDate" => "2015-07-02",
      "weight" => {
        "value" => 25,
        "units" => "ounces"
      },
      "dimensions" => {
        "units" => "inches",
        "length" => 7,
        "width" => 5,
        "height" => 6
      },
      "insuranceOptions" => {
        "provider" => "carrier",
        "insureShipment" => 1,
        "insuredValue" => 200
      },
      "internationalOptions" => {
        "contents" => undef,
            "customsItems" => undef
      },
      "advancedOptions" => {
        "warehouseId" => 0,
        "nonMachinable" => 0,
        "saturdayDelivery" => 0,
        "containsAlcohol" => 0,
        "storeId" => 0,
        "customField1" => "Custom data",
        "customField2" => "Per UI settings, this information",
        "customField3" => "can appear on some carrier's shipping labels",
        "source" => "Webstore"
      }
    });

=head2 deleteOrder

    my $is_success = $ws->deleteOrder($OrderID);

=head2 request

    my $data = $ws->request('customers');
    my $data = $ws->request('warehouses');

internal use

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
