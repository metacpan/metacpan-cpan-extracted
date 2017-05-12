package XAO::testcases::FS::placeholders;
use strict;
use XAO::Utils;
use Error qw(:try);

use base qw(XAO::testcases::FS::base);

# If we have /Customers/Orders and /Orders and then drop_placeholder on
# /Customers it also drops /Orders from _MEMORY_, not from the
# database. Should not do that!
#
# AM: 2003-10-09
#
sub test_double_drop_20031009 {
    my $self=shift;
    my $odb=$self->get_odb();

    my $root=$odb->fetch('/');
    $root->add_placeholder(
        name        => 'Orders',
        type        => 'list',
        class       => 'Data::Order',
        key         => 'order_id',
    );

    $self->assert($root->exists('Orders'),
                  "Orders was not created");

    my $c1=$root->get('Customers')->get('c1');
    $c1->add_placeholder(
        name        => 'Orders',
        type        => 'list',
        class       => 'Data::Product',
        key         => 'order_id',
    );

    $self->assert($c1->exists('Orders'),
                  "c1/Orders was not created");

    $root->drop_placeholder('Customers');

    $self->assert(!$root->exists('Customers'),
                  "Customers exists after drop_placeholder (1)");
    $self->assert($root->exists('Orders'),
                  "Orders does not exist, but should");

    $root->add_placeholder(
        name        => 'Customers',
        type        => 'list',
        class       => 'Data::Customer',
        key         => 'order_id',
    );

    $self->assert($root->exists('Customers'),
                  "Customers was not created");

    $root->drop_placeholder('Customers');

    $self->assert(!$root->exists('Customers'),
                  "Customers exists after drop_placeholder (2)");
    $self->assert($root->exists('Orders'),
                  "Orders does not exist, but should");

    $root->drop_placeholder('Orders');

    $self->assert(!$root->exists('Customers'),
                  "Customers exists after drop_placeholder (3)");
    $self->assert(!$root->exists('Orders'),
                  "Orders exists after drop_placeholder");
}

###############################################################################

sub test_key_charset {
    my $self=shift;

    my $odb=$self->get_odb();

    my $customer=$odb->fetch('/Customers/c1');
    $self->assert(ref($customer),
                  "Can't fetch /Customers/c1");

    $customer->add_placeholder(
        name        => 'Orders',
        type        => 'list',
        class       => 'Data::Order',
        key         => 'order_id',
    );

    my $orders=$customer->get('Orders');
    my $no=$orders->get_new;

    my $cs=$no->describe('order_id')->{'key_charset'};
    $self->assert($cs eq 'binary',
                  "Got wrong key_charset, method 1, expected 'binary', got '$cs'");

    $cs=$orders->key_charset;
    $self->assert($cs eq 'binary',
                  "Got wrong key_charset, method 2, expected 'binary', got '$cs'");

    $no->add_placeholder(
        name        => 'name',
        type        => 'text',
        maxlength   => 10,
    );

    my $k1='ABCdef';
    my $k2='abcDEF';

    $no->put(name => 'k1');
    $orders->put($k1 => $no);

    $no->put(name => 'k2');
    $orders->put($k2 => $no);

    my $v1=$orders->get($k1)->get('name');
    my $v2=$orders->get($k2)->get('name');

    $self->assert($v1 eq 'k1',
                  "Expected 'k1', got '$v1', key_charset 'binary'");
    $self->assert($v2 eq 'k2',
                  "Expected 'k2', got '$v2', key_charset 'binary'");

    $customer->drop_placeholder('Orders');

    ##
    # Now checking on latin1 key_charset, it should be case insensitive
    #
    $customer->add_placeholder(
        name        => 'Orders',
        type        => 'list',
        class       => 'Data::Order',
        key         => 'order_id',
        key_charset => 'latin1',
    );

    $orders=$customer->get('Orders');
    $no=$orders->get_new;

    $cs=$no->describe('order_id')->{'key_charset'};
    $self->assert($cs eq 'latin1',
                  "Got wrong key_charset, method 1, expected 'latin1', got '$cs'");

    $cs=$orders->key_charset;
    $self->assert($cs eq 'latin1',
                  "Got wrong key_charset, method 2, expected 'latin1', got '$cs'");

    $no->add_placeholder(
        name        => 'name',
        type        => 'text',
        maxlength   => 10,
    );

    my $k='abcdeFGHIK';
    $no->put(name => 'zzzzzz');
    $orders->put($k => $no);

    for($k,lc($k),uc($k)) {
        $self->assert($orders->exists($_),
                      "Expected '$_' to exist, key_charset 'latin1'");
    }
}

###############################################################################

sub test_key_length {
    my $self=shift;

    my $odb=$self->get_odb();

    my $customer=$odb->fetch('/Customers/c1');
    $self->assert(ref($customer),
                  "Can't fetch /Customers/c1");

    $customer->add_placeholder(
        name        => 'Orders',
        type        => 'list',
        class       => 'Data::Order',
        key         => 'order_id',
        key_length  => 40,
    );

    my $orders=$customer->get('Orders');
    my $no=$orders->get_new;

    my $kl=$no->describe('order_id')->{'key_length'};
    $self->assert($kl == 40,
                  "Got wrong key length, method 1");

    $kl=$orders->key_length;
    $self->assert($kl == 40,
                  "Got wrong key length, method 2");

    $no->add_placeholder(
        name        => 'name',
        type        => 'text',
        maxlength   => 10,
    );

    my $k1=('Z' x 35) . '11';
    my $k2=('Z' x 35) . '22';

    $no->put(name => 'k1');
    $orders->put($k1 => $no);

    $no->put(name => 'k2');
    $orders->put($k2 => $no);

    my $v1=$orders->get($k1)->get('name');
    my $v2=$orders->get($k2)->get('name');

    $self->assert($v1 eq 'k1',
                  "Expected 'k1', got '$v1'");
    $self->assert($v2 eq 'k2',
                  "Expected 'k2', got '$v2'");
}

###############################################################################

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

    $o1->add_placeholder(name => 'foo', type => 'text', maxlength => 50);
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
                              type => 'text',
                              maxlength => 50);
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
        uns => {
            type => 'integer',
            minvalue => 0,
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
                    maxlength => 50,
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

    foreach my $name (qw(newf name text integer uns Orders)) {
        $self->assert($cust->exists($name),
                      "Field ($name) doesn't exist after build_structure()");
        if($name eq 'uns') {
            my $min=$cust->describe($name)->{minvalue};
            $self->assert($min == $structure{uns}->{minvalue},
                          "Minvalue is wrong for 'uns' ($min)");
            my $max=$cust->describe($name)->{maxvalue};
            $self->assert($max == 0xFFFFFFFF,
                          "Maxvalue is wrong for 'uns' ($max)");
        }

        next unless $name eq 'newf';
        $self->assert($cust->describe($name)->{index},
                      "No indication of index in the created field ($name)");
    }
}

###############################################################################

1;
