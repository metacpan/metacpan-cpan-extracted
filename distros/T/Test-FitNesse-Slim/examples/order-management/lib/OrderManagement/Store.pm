package OrderManagement::Store;

use strict;
use warnings;
use OrderManagement::Pricing;

sub new {
  my ($class) = @_;
  return bless {
    customers => {
      'C-100' => { id => 'C-100', tier => 'preferred', active => 1 },
      'C-200' => { id => 'C-200', tier => 'standard', active => 1 },
      'C-300' => { id => 'C-300', tier => 'preferred', active => 0 },
    },
    products => {
      COFFEE => { sku => 'COFFEE', name => 'House coffee', unit_price_cents => 500, on_hand => 10, reserved => 0 },
      TEA    => { sku => 'TEA',    name => 'Breakfast tea', unit_price_cents => 300, on_hand => 5, reserved => 0 },
      MUG    => { sku => 'MUG',    name => 'Ceramic mug', unit_price_cents => 1_200, on_hand => 2, reserved => 0 },
    },
    orders => {
      'ORD-021' => { id => 'ORD-021', customer_id => 'C-200', status => 'submitted', lines => [], reserved => 0, subtotal_cents => 600, discount_cents => 0, shipping_cents => 500, total_cents => 1_100 },
      'ORD-022' => { id => 'ORD-022', customer_id => 'C-100', status => 'submitted', lines => [], reserved => 0, subtotal_cents => 2_000, discount_cents => 200, shipping_cents => 500, total_cents => 2_300 },
      'ORD-023' => { id => 'ORD-023', customer_id => 'C-200', status => 'submitted', lines => [], reserved => 0, subtotal_cents => 1_200, discount_cents => 0, shipping_cents => 500, total_cents => 1_700 },
    },
    next_order => 1,
  }, $class;
}

sub customer {
  my ($self, $customer_id) = @_;
  return $self->{customers}{$customer_id};
}

sub customer_eligible {
  my ($self, $customer_id) = @_;
  my $customer = $self->customer($customer_id) or return 0;
  return $customer->{active} ? 1 : 0;
}

sub available {
  my ($self, $sku) = @_;
  my $product = $self->{products}{$sku} or return;
  return $product->{on_hand} - $product->{reserved};
}

sub inventory_rows {
  my ($self) = @_;
  return [ map {
    my $product = $self->{products}{$_};
    +{
      sku => $product->{sku},
      product => $product->{name},
      'unit price' => OrderManagement::Pricing->from_cents($product->{unit_price_cents}),
      'on hand' => "$product->{on_hand}",
      reserved => "$product->{reserved}",
      available => "" . ($product->{on_hand} - $product->{reserved}),
    }
  } sort keys %{$self->{products}} ];
}

sub replenishment_rows {
  my ($self) = @_;
  return [ sort {
    $a->{available} <=> $b->{available} || $a->{sku} cmp $b->{sku}
  } @{$self->inventory_rows} ];
}

sub create_order {
  my ($self, $customer_id) = @_;
  return unless $self->customer($customer_id);
  my $order_id = sprintf 'ORD-%03d', $self->{next_order}++;
  $self->{orders}{$order_id} = {
    id => $order_id,
    customer_id => $customer_id,
    status => 'draft',
    lines => [],
    reserved => 0,
    subtotal_cents => 0,
    discount_cents => 0,
    shipping_cents => 0,
    total_cents => 0,
  };
  return $order_id;
}

sub add_item {
  my ($self, $order_id, $sku, $quantity) = @_;
  my $order = $self->{orders}{$order_id} or return (0, 'Order was not found.');
  return (0, 'Items can only be added to a draft order.')
    unless $order->{status} eq 'draft';
  return (0, "Product $sku was not found.") unless $self->{products}{$sku};
  return (0, 'Quantity must be a positive whole number.')
    unless defined($quantity) && $quantity =~ /\A[1-9]\d*\z/;

  my $product = $self->{products}{$sku};
  push @{$order->{lines}}, {
    sku => $sku,
    product => $product->{name},
    quantity => 0 + $quantity,
    unit_price_cents => $product->{unit_price_cents},
  };
  $order->{subtotal_cents} += $product->{unit_price_cents} * $quantity;
  my $customer = $self->customer($order->{customer_id});
  require OrderManagement::Pricing;
  my $quote = OrderManagement::Pricing->quote(
    $customer->{tier}, $order->{subtotal_cents}
  );
  @{$order}{qw(discount_cents shipping_cents total_cents)} =
    @{$quote}{qw(discount_cents shipping_cents total_cents)};
  return (1, '');
}

sub order_subtotal {
  my ($self, $order_id) = @_;
  my $order = $self->{orders}{$order_id} or return;
  return $order->{subtotal_cents};
}

sub reserve_inventory {
  my ($self, $order_id) = @_;
  my $order = $self->{orders}{$order_id} or return (0, 'Order was not found.');
  return (0, 'Only a draft order can reserve inventory.')
    unless $order->{status} eq 'draft';
  my $customer = $self->customer($order->{customer_id});
  return (0, 'Customer is not eligible to place an order.')
    unless $customer && $customer->{active};
  return (0, 'An order must contain at least one item.') unless @{$order->{lines}};

  my %required;
  $required{$_->{sku}} += $_->{quantity} for @{$order->{lines}};
  for my $sku (sort keys %required) {
    my $available = $self->available($sku);
    return (0, "Insufficient stock for $sku: requested $required{$sku}, available $available.")
      if $required{$sku} > $available;
  }

  $self->{products}{$_}{reserved} += $required{$_} for keys %required;
  $order->{reserved} = 1;
  $order->{status} = 'reserved';
  return (1, '');
}

sub submit_order {
  my ($self, $order_id) = @_;
  my $order = $self->{orders}{$order_id} or return (0, 'Order was not found.');
  my $customer = $self->customer($order->{customer_id});
  return (0, 'Customer is not eligible to place an order.')
    unless $customer && $customer->{active};
  return (0, 'Inventory must be reserved before submission.')
    unless $order->{status} eq 'reserved' && $order->{reserved};
  $order->{status} = 'submitted';
  return (1, '');
}

sub order_status {
  my ($self, $order_id) = @_;
  return $self->{orders}{$order_id}{status} if $self->{orders}{$order_id};
  return;
}

sub order_total {
  my ($self, $order_id) = @_;
  return $self->{orders}{$order_id}{total_cents} if $self->{orders}{$order_id};
  return;
}

sub orders_for_customer {
  my ($self, $customer_id) = @_;
  return [ map { $self->{orders}{$_} }
    grep { $self->{orders}{$_}{customer_id} eq $customer_id }
    sort keys %{$self->{orders}} ];
}

1;
