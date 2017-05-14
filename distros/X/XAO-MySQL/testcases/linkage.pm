package testcases::linkage;
use strict;
use XAO::Utils;

use base qw(testcases::base);

sub test_linkage {
    my $self=shift;
    my $odb=$self->get_odb;

    my $customer=$odb->fetch('/Customers/c1');
    $self->assert($customer, "Can't load a customer");

    $self->assert(defined($customer->can('container_object')),
                  "Can't call container_object() on FS::Hash object!");

    my $list=$customer->container_object;
    $self->assert(ref($list),
                  "Can't get container_object for customer");
    $self->assert($list->get('c2')->container_key eq 'c2',
                  "Something is wrong with the customers list");

    $self->assert(defined($list->can('container_object')),
                  "Can't call container_object() on FS::List object!");

    my $global=$list->container_object;
    $self->assert(ref($global) && $global->get('project'),
                  "Got wrong global object from List");
}

sub test_uri {
    my $self = shift;
    my $odb = $self->get_odb;

    ##
    # Creating deeper structure required for better tests.
    #
    $odb->fetch('/Customers/c1')->add_placeholder(
        name    => 'Orders',
        type    => 'list',
        class   => 'Data::Order',
        key     => 'order_id',
    );
    my $orders=$odb->fetch('/Customers/c1/Orders');
    $orders->put(o1 => $orders->get_new());
    $orders->put(o2 => $orders->get_new());

    my $o1=$odb->fetch('/Customers/c1/Orders/o1');
    $self->assert(ref($o1),
                  "Can't get /Customers/c1/Orders/o1");
    my $uri=$o1->uri;
    $self->assert($uri eq '/Customers/c1/Orders/o1',
                  "Wrong uri() -- '$uri' ne '/Customers/c1/Orders/o1'");

    $orders=$o1->container_object;
    $self->assert(ref($orders),
                  "Can't get container object from o1");
    $uri = $orders->uri;
    $self->assert($uri eq '/Customers/c1/Orders',
                  "Wrong uri() -- '$uri' ne '/Customers/c1/Orders'");

    my $c1=$orders->container_object();
    $self->assert(ref($c1),
                  "Can't get container_object() from Orders");
    $uri=$c1->uri;
    $self->assert($uri eq '/Customers/c1',
                  "Wrong uri() -- '$uri' ne '/Customers/c1'");

    my $customers=$c1->container_object;
    $self->assert(ref($customers),
                  "Can't get container_object from c1");
    $uri=$customers->uri;
    $self->assert($uri eq '/Customers',
                  "Wrong uri() -- '$uri' ne '/Customers'");

    my $global=$customers->container_object();
    $self->assert(ref($global),
                  "Can't get container_object from Customers");
    $uri=$global->uri;
    $self->assert($uri eq '/',
                  "Wrong uri() -- '$uri' ne '/'");
}

1;
