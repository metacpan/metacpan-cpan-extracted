package testcases::lists;
use strict;
use XAO::Utils;
use XAO::Objects;

use base qw(testcases::base);

sub new_cust {
    my $self=shift;
    my $nref=shift;

    my $odb=$self->get_odb();

    my $newcust=XAO::Objects->new(objname => 'Data::Customer',
                                  glue => $odb);
    $self->assert(ref($newcust), 'Detached customer creation failure');

    $$nref='New Customer - ' . sprintf('%5.2f',rand(100));
    $newcust->put(name => $$nref);
    my $got=$newcust->get('name');
    $self->assert($$nref eq $got, "We got ($got) not what we stored ($$nref)");

    $newcust;
}

##
# Checks that two customer objects are different.
#
sub check_separation {
    my $self=shift;
    my ($cust1,$clist,$c2id)=@_;

    my $cust2=$clist->get($c2id);
    $self->assert(ref($cust2),
                  "Failure retrieving customer ($c2id)");

    my $name1='c1 name 11';
    my $name2='c2 name 2222';
    $cust1->put(name => $name1);
    $cust2->put(name => $name2);
    my $got1=$cust1->get('name');
    my $got2=$cust2->get('name');

    $self->assert($got1 eq $name1,
                  "Got ($got1) not what we stored ($name1) (1)");
    $self->assert($got2 eq $name2,
                  "Got ($got2) not what we stored ($name2) (2)");

    $cust2->put(name => $name2);
    $cust1->put(name => $name1);
    $got1=$cust1->get('name');
    $got2=$cust2->get('name');

    $self->assert($got1 eq $name1,
                  "Got ($got1) not what we stored ($name1) (3)");
    $self->assert($got2 eq $name2,
                  "Got ($got2) not what we stored ($name2) (4)");
}

##
# Puts new hash object into storage under generated name. Checks various
# key formats.
#
sub test_store_nameless_object {
    my $self=shift;

    my $odb=$self->get_odb();

    my $name;
    my $newcust=$self->new_cust(\$name);

    my $clist=$odb->fetch('/Customers');
    $self->assert(ref($clist),
                  "Can't fetch('Customers')");

    my $id=$clist->put($newcust);
    $self->assert(defined($id) && $id && $id=~/^\w{1,20}$/,
                  "Wrong ID generated ($id)");

    my $got=$odb->fetch("/Customers/$id/name");
    $self->assert($name eq $got,
                  "We fetched ($got) not what we stored ($name)");

    $self->check_separation($newcust,$clist,$id);

    my %matrix=(
        '<$RANDOM$>'            => qr/^\w{8}$/,
        '<$AUTOINC$>'           => qr/^\d+$/,
        'X<$AUTOINC/10$>Y'      => qr/^X\d{10}Y$/,
        '<$GMTIME$>_<$RANDOM$>' => qr/^\d+_\w{8}$/,
        'RND<$RANDOM$>X<$DATE$>'=> qr/RND\w{8}X\d{14}/,
    );
    my $root=$odb->fetch('/');
    foreach my $key_format (keys %matrix) {
        my $re=$matrix{$key_format};
        $root->drop_placeholder('Customers');
        $root->build_structure(
            Customers => {
                type        => 'list',
                class       => 'Data::Customer',
                key         => 'customer_id',
                key_format  => $key_format,
                structure   => {
                    name => {
                        type        => 'text',
                        maxlength   => 100,
                    },
                },
            },
        );
        $clist=$root->get('Customers');
        $newcust=$self->new_cust(\$name);
        $id=$clist->put($newcust);
        $self->assert($id=~$re,
                      "Wrong ID generated ($id)");
        $got=$odb->fetch("/Customers/$id/name");
        $self->assert($name eq $got,
                      "We fetched ($got) not what we stored ($name)");
        $self->check_separation($newcust,$clist,$id);
    }
}

##
# Puts new hash object into storage under given name
#
sub test_store_named_object {
    my $self=shift;

    my $odb=$self->get_odb();

    my $name;
    my $newcust=$self->new_cust(\$name);

    my $clist=$odb->fetch('/Customers');
    $self->assert(ref($clist), "Can't fetch('Customers')");

    $clist->put(newcust => $newcust);

    my $got=$odb->fetch('/Customers/newcust/name');
    $self->assert($name eq $got,
                  "We fetched ($got) not what we stored ($name)");

    $self->check_separation($newcust,$clist,'newcust');

    ##
    # Now checking how replacement works as 'newcust' already exists at
    # this point.
    #
    $name='new name';
    $newcust->put(name => $name);
    $clist->put(newcust => $newcust);
    $got=$odb->fetch('/Customers/newcust/name');
    $self->assert($name eq $got,
                  "We fetched ($got) not what we stored ($name)");

    $self->check_separation($newcust,$clist,'newcust');
}

sub test_cloning {
    my $self=shift;

    my $odb=$self->get_odb();

    my $c1=$odb->fetch('/Customers/c1');
    $self->assert(ref($c1), "Can't fetch('Customers/c1')");

    my $clist=$odb->fetch('/Customers');
    $self->assert(ref($clist), "Can't fetch('Customers')");

    my $id=$clist->put($c1);
    my $n1=$c1->get('name');
    my $c2=$clist->get($id);
    my $n2=$c2->get('name');

    $self->assert($n1 eq $n2,
                  "Cloned name ($n2) differs from the original ($n1) (1)");

    $self->check_separation($c1,$clist,$id);

    $id=$clist->put(c3 => $c1);
    $n1=$c1->get('name');
    $c2=$clist->get($id);
    $n2=$c2->get('name');

    $self->assert($n1 eq $n2,
                  "Cloned name ($n2) differs from the original ($n1) (2)");

    $self->check_separation($c1,$clist,$id);
}

sub test_container_key {
    my $self=shift;
    my $odb=$self->get_odb();

    my $clist=$odb->fetch('/Customers');
    my $name=$clist->container_key();
    $self->assert($name eq 'Customers',
                  "Container_key returned wrong value ('$name'!='Customers')");
}

sub test_keys {
    my $self=shift;
    my $odb=$self->get_odb();

    my $clist=$odb->fetch('/Customers');
    my $keys=join(',',sort $clist->keys);

    $self->assert($keys eq 'c1,c2',
                  "Customers->keys returned wrong value ('$keys'!='c1,c2')");

    my @v=$clist->values();
    $self->assert(@v == 2,
                  "Customers->values returned wrong number of items");
}

sub test_exists {
    my $self=shift;
    my $odb=$self->get_odb();

    my $clist=$odb->fetch('/Customers');

    $self->assert($clist->exists('c1'),
                  "Exists() returned wrong value for 'c1'");

    $self->assert(! $clist->exists('nonexistent'),
                  "Exists() returned wrong value fro 'nonexistent'");
}

sub test_list_describe {
    my $self=shift;
    
    my $odb = $self->{odb};
    
    my $list=$odb->fetch('/Customers');

    $self->assert($list, "Can't fetch List object");
    
    $self->assert(defined($list->can('describe')),
                  "Can't call function 'describe()' on Data::System::List object!");

    my $desc=$list->describe();
    $self->assert(ref($desc) eq 'HASH',
                  "List description is not a hash reference");
    $self->assert($desc->{type} eq 'list',
                  "Type of Customers is not 'list'");
    $self->assert($desc->{class} eq 'Data::Customer',
                  "Class of Customers is not 'Data::Customer'");
    $self->assert($desc->{key} => 'customer_id',
                  "Key for Customers is not 'customer_id'");
}

1;
