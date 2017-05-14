package testcases::collection;
use strict;
use XAO::Utils;
use XAO::Objects;

use base qw(testcases::base);

sub test_everything {
    my $self=shift;
    my $odb=$self->get_odb();

    my $clist=$odb->collection(class => 'Data::Customer');
    $self->assert(ref($clist),
                  "Can't create a collection");

    $self->assert($clist->objtype eq 'Collection',
                  "Objtype() is not 'Collection'");

    $self->assert($clist->objname eq 'FS::Collection',
                  "Objname() is not 'FS::Collection'");

    my @kk=$clist->keys;
    $self->assert(@kk == 2,
                  "Wrong number of items in the collection");

    my $c=$clist->get($kk[0]);
    $self->assert($c->objtype eq 'Hash',
                  "Got something wrong from collection");

    my $kn=$c->container_key();
    $self->assert($kn eq 'c1' || $kn eq 'c2',
                  "Container_key returned wrong value ($kn)");

    my $name='New Name';
    $c->put(name => $name);
    my $got=$c->get('name');
    $self->assert($got eq $name,
                  "Something wrong with the hash object we got ($got!=$name)");

    my $uri=$c->uri;
    $self->assert($uri && $uri =~ '/Customers/c?',
                  "Wrong URI ($uri)");
}

sub test_deeper {
    my $self=shift;
    my $odb=$self->get_odb();

    my $c=$odb->fetch('/Customers/c2');
    $c->add_placeholder(name => 'Orders',
                        type => 'list',
                        class => 'Data::Order',
                        key => 'order_id',
                       );
    my $orders=$c->get('Orders');
    my $o=$orders->get_new();
    $o->add_placeholder(name => 'foo',
                        type => 'text');
    $o->put(foo => 'test');
    $orders->put($o);
    $o->put(foo => 'fubar');
    $orders->put($o);
    $o->put(foo => 'junk');
    $orders->put($o);

    my $coll=$odb->collection(class => 'Data::Order');
    $self->assert(ref($coll),
                  "Can't create a collection");

    $self->assert($coll->objtype eq 'Collection',
                  "Objtype() is not 'Collection'");

    $self->assert($coll->objname eq 'FS::Collection',
                  "Objname() is not 'FS::Collection'");

    my @kk=$coll->keys;
    $self->assert(@kk == 3,
                  "Wrong number of items in the collection");

    my $item=$coll->get($kk[1]);
    $self->assert($item->objtype eq 'Hash',
                  "Got something wrong from collection");

    my $foo='New Name';
    $item->put(foo => $foo);
    my $got=$item->get('foo');
    $self->assert($got eq $foo,
                  "Something wrong with the hash object we got ($got!=$foo)");

    my $uri=$item->uri;
    $self->assert($uri && $uri =~ '^/Customers/c2/Orders/',
                  "Wrong URI ($uri)");

    $item=$coll->get($kk[0]);
    $self->assert($item->objtype eq 'Hash',
                  "Got something wrong from collection");

    $item=$coll->get($kk[2]);
    $self->assert($item->objtype eq 'Hash',
                  "Got something wrong from collection");

    my $list=$coll->search('foo', 'cs', 'New');
    $self->assert($list && scalar(@$list),
                  "Wrong search results on collection");

    my $id=$list->[0];
    $item=$coll->get($id);
    $self->assert(ref($item),
                  "Can't get order reference using search results");

    $got=$item->get('foo');
    $self->assert($got =~ /New/,
                  "Wrong search results from collection ($got !~ /New/)");

    $foo='Super-Duper';
    $item->put(foo => $foo);
    $got=$item->get('foo');
    $self->assert($got eq $foo,
                  "Something wrong with the hash object we got ($got!=$foo)");
}

1;
