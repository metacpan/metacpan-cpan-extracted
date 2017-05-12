#!/usr/bin/perl -w
use XML::Node;

my $item = "";
my $quantity = "";
my $id = "";
my $date = "";
my $orders = "";

$p = XML::Node->new();

$p->register(">Orders","start" => \&handle_orders_start);
$p->register(">Orders","char" => \$orders);
$p->register(">Orders>Order:ID","attr" => \$id);
$p->register(">Orders>Order:Date","attr" => \$date);
$p->register(">Orders>Order>Item","char" => \$item);
$p->register(">Orders>Order>Quantity","char" => \$quantity);
$p->register(">Orders>Order","end" => \&handle_order_end);
$p->register(">Orders","end" => \&handle_orders_end);

print "Processing file [orders.xml]...\n";
$p->parsefile("orders.xml");

sub handle_orders_start
{
    print "Start of all orders\n-----\n$orders\n----\n";
}

sub handle_order_end
{
    print "Found order [$id] [$date] -- Item: [$item] Quantity: [$quantity]\n";
    $date = "";
    $id="";
    $item = "";
    $quantity = "";
}

sub handle_orders_end
{
    print "End of all orders\n-----\n$orders\n----\n";
}

