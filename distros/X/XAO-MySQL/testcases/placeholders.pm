package testcases::placeholders;
use strict;
use XAO::Utils;
use Data::Dumper;
use Error qw(:try);

use base qw(testcases::base);

sub test_same_field_name {
    my $self=shift;

    my $odb=$self->get_odb();

    my $customer=$odb->fetch('/Customers/c1');
    $self->assert(ref($customer),
                  "Can't fetch /Customers/c1");

    $customer->add_placeholder(name => 'first_name',
                               type => 'text',
                               maxlength => 20);

    my $thrown=1;
    try {
        $customer->add_placeholder(name => 'first_name',
                                   type => 'text',
                                   maxlength => 20);
    } otherwise {
        $thrown=1;
    };

    $self->assert($thrown,
                  "Succeeded in adding new placeholder with already used name!");

    $customer->drop_placeholder('first_name');
}

sub test_data_placeholder {
    my $self=shift;

    my $odb=$self->get_odb();

    my $customer=$odb->fetch('/Customers/c1');
    $self->assert(ref($customer),
                  "Can't fetch /Customers/c1");

    $customer->add_placeholder(name => 'first_name',
                               type => 'text',
                               maxlength => 20);

    my $name='John Doe';
    $customer->put(first_name => $name);
    my $got=$customer->get('first_name');
    $self->assert($name eq $got,
                  "Got ($got) not what was stored ($name)");

    $customer->drop_placeholder('first_name');
}

sub test_list_placeholder {
    my $self=shift;

    my $odb=$self->get_odb();

    my $customer=$odb->fetch('/Customers/c1');
    $self->assert(ref($customer),
                  "Can't fetch /Customers/c1");

    $customer->add_placeholder(name   => 'Orders',
                               type   => 'list',
                               class  => 'Data::Order',
                               key    => 'order_id');

    my $cust_orders=$customer->get('Orders');
    $self->assert(ref($cust_orders),
                  "Can't get reference to Orders list from /Customers/c1");

    my $o1=$odb->new(objname => 'Data::Order');
    $self->assert(ref($o1),
                  "Can't create an empty order");

    $o1->add_placeholder(name => 'foo', type => 'text');
    $o1->put(foo => 'bar');

    $cust_orders->put(o0 => $o1);
    $cust_orders->put(o1 => $o1);
    $cust_orders->put(o2 => $o1);
    my $order=$odb->fetch('/Customers/c1/Orders/o1');
    $self->assert(ref($order),
                  "Can't save order into /Customers/c1");
    my $got=$order->get('foo');
    $self->assert($got eq 'bar',
                  "Got wrong value in the order ($got!='bar')");

    my @k=sort $cust_orders->keys;
    $self->assert($k[2] eq 'o2',
                  "Got wrong key in the key list (".join(',',@k).")");

    $order->put(foo => 'new');
    $got=$odb->fetch('/Customers/c1/Orders/o1/foo');
    $self->assert($got eq 'new',
                  "Got wrong value in the order ($got!='new')");

    ##
    # Checking how automatic naming works
    #
    my $c2orders=$odb->fetch('/Customers/c2/Orders');
    $self->assert(ref($c2orders),
                  "Can't fetch /Customers/c2/Orders");

    $o1->put(foo => 'under c2');
    my $newname=$c2orders->put($o1);
    $got=$odb->fetch("/Customers/c2/Orders/$newname/foo");
    $self->assert($got eq 'under c2',
                  "Got wrong value in the order ($got!='under c2')");

    ##
    # Adding third level placeholder on Order.
    #
    $order->add_placeholder(name   => 'Products',
                            type   => 'list',
                            class  => 'Data::Product',
                            key    => 'product_id');
    my $products=$order->get('Products');
    $self->assert(ref($products),
                  "Can't get reference to Products list from /Customers/c1/Orders/o1");
    my $product=$products->get_new();
    $product->add_placeholder(name => 'name',
                              type => 'text');
    $product->put(name => 'test');
    my $newprod=$products->put($product);
    $product=$products->get($newprod);
    $self->assert(ref($product),
                  "Can't put test product into Products");
    $got=$product->get('name');
    $self->assert($got eq 'test',
                  "Got not what was stored into product ($got!='test')");

    ##
    # Deleting
    #
    $cust_orders->delete('o1');
    my $thrown=0;
    try {
        $cust_orders->get('o1');
    } otherwise {
        $thrown=1;
    };
    $self->assert($thrown,
                  "Can still retrieve deleted Order");
    $c2orders->delete($newname);
    $thrown=0;
    try {
        $c2orders->get($newname);
    } otherwise {
        $thrown=1;
    };
    $self->assert($thrown,
                  "Deleted order c2/$newname is still there");

    ##
    # Deleting lists
    #
    $customer->drop_placeholder('Orders');
    $got=1;
    try {
        $order=$customer->get('Orders');
    } otherwise {
        $got=0;
    };
    $self->assert(!$got,
                  "Still can retrieve Orders after dropping placeholder");
}

###############################################################################

##
# Checking that it is impossible to create more then one list for the
# same class.
#
sub test_multiple_same_class {
    my $self=shift;

    my $odb=$self->get_odb();

    my $customer=$odb->fetch('/Customers/c1');
    $self->assert(ref($customer),
                  "Can't fetch /Customers/c1");

    $customer->add_placeholder(name   => 'Orders',
                               type   => 'list',
                               class  => 'Data::Order',
                               key    => 'order_id');

    my $root=$odb->fetch('/');
    $self->assert(ref($root),
                  "Can't fetch reference to /");

    my $created=1;
    try {
        $root->add_placeholder(name      => 'rootorders',
                               type      => 'list',
                               class     => 'Data::Order',
                               key       => 'root_order_id',
                               connector => 'root_uid');
    } otherwise {
        $created=0;
    };
    $self->assert(! $created,
                  "Succeeded in creating second list of the same class");

    my $got=1;
    try {
        $root->get('rootorders');
    } otherwise {
        $got=0;
    };
    $self->assert(!$got,
                  "Succeeded in creating second list of the same class (After error! Weird..)");
}

sub test_build_structure {
    my $self=shift;
    my $odb=$self->get_odb;

    my $cust=$odb->fetch('/Customers/c1');

    # Otherwise UNIQUE option would not work
    #
    $odb->fetch('/Customers')->delete('c2');

    my %structure=(
        name => {
            type => 'text',
            maxlength => 40,
        },
        text => {
            type => 'text',
            maxlength => 200,
            index => 1,
        },
        integer => {
            type => 'integer',
            minvalue => 0,
            maxvalue => 100
        },
        uq => {
            type => 'real',
            minvalue => 123,
            maxvalue => 234,
            unique => 1,
        },
        Orders => {
            type      => 'list',
            class     => 'Data::Order',
            key       => 'order_id',
            structure => {
                total => {
                    type => 'real',
                    default => 123.34,
                },
                foo => {
                    type => 'text',
                },
            },
        },
    );

    $cust->build_structure(\%structure);
    foreach my $name (qw(name text integer Orders)) {
        $self->assert($cust->exists($name),
                      "Field ($name) doesn't exist after build_structure()");
    }

# TODO:
# We need to re-load database structure from disk at this
# point. Otherwise index and unique are not really tested.
# am@xao.com, 10/1/2001
#

    $structure{newf}={
        type => 'real',
        minvalue => 123,
        maxvalue => 234,
        index => 1,
    };
    $cust->build_structure(\%structure);

    foreach my $name (qw(newf name text integer Orders)) {
        $self->assert($cust->exists($name),
                      "Field ($name) doesn't exist after build_structure()");
        next unless $name eq 'newf';
        $self->assert($cust->describe($name)->{index},
                      "No indication of index in the created field ($name)");
    }
}

###############################################################################

1;
