package OrderManagement::Fixtures::OrderWorkflow;

use strict;
use warnings;
use OrderManagement::Pricing;
use OrderManagement::Store;

sub new {
  my ($class) = @_;
  return bless { store => OrderManagement::Store->new, last_error => '' }, $class;
}

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['String'], return => 'String' } if $method eq 'create_order_for';
  return { parameters => ['String', 'Integer', 'String'], return => 'Boolean' }
    if $method eq 'add_item_quantity_to_order';
  return { parameters => ['String'], return => 'Boolean' }
    if $method eq 'reserve_inventory_for' || $method eq 'submit_order';
  return { parameters => ['String'], return => 'String' } if $method eq 'status_of_order';
  return { parameters => ['String'], return => 'Integer' } if $method eq 'subtotal_of_order';
  return { parameters => ['String'], return => 'String' } if $method eq 'total_of_order';
  return { parameters => [], return => 'String' } if $method eq 'last_error';
  return;
}

sub create_order_for {
  my ($self, $customer_id) = @_;
  my $id = $self->{store}->create_order($customer_id);
  $self->{last_error} = defined($id) ? '' : 'Customer was not found.';
  return $id;
}

sub add_item_quantity_to_order {
  my ($self, $sku, $quantity, $order_id) = @_;
  my ($accepted, $message) = $self->{store}->add_item($order_id, $sku, $quantity);
  $self->{last_error} = $message;
  return $accepted;
}

sub reserve_inventory_for {
  my ($self, $order_id) = @_;
  my ($accepted, $message) = $self->{store}->reserve_inventory($order_id);
  $self->{last_error} = $message;
  return $accepted;
}

sub submit_order {
  my ($self, $order_id) = @_;
  my ($accepted, $message) = $self->{store}->submit_order($order_id);
  $self->{last_error} = $message;
  return $accepted;
}

sub status_of_order { $_[0]{store}->order_status($_[1]) // '' }
sub subtotal_of_order { $_[0]{store}->order_subtotal($_[1]) // 0 }
sub total_of_order {
  OrderManagement::Pricing->from_cents($_[0]{store}->order_total($_[1]) // 0);
}
sub last_error { $_[0]{last_error} }

1;
