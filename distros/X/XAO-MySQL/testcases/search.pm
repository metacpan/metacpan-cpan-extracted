package testcases::search;
use strict;
use XAO::Utils;
use XAO::Objects;

use base qw(testcases::base);

sub test_search {
    my $self=shift;

    my $odb=$self->get_odb();

    my $custlist=$odb->fetch('/Customers');

    my $customer=$custlist->get_new();

    $self->assert(ref($customer),
                  "Can't create Customer");

    $customer->add_placeholder(name => 'short',
                               type => 'text',
                               maxlength => 100,
                               index => 1);

    $customer->add_placeholder(name => 'long',
                               type => 'text',
                               maxlength => 1000);

    ##
    # For deeper search
    #
    $customer->add_placeholder(name => 'Products',
                               type => 'list',
                               class => 'Data::Product',
                               key => 'product_id');
    my $product=XAO::Objects->new(objname => 'Data::Product',
                                  glue => $odb);
    $product->add_placeholder(name => 'price',
                              type => 'real',
                              maxvalue => 1000,
                              minvalue => 0);

    ##
    # Words to fill descriptions. Tests depend on exact sequence and
    # number and content of them. Do not alter!
    #
    my @words=split(/\s+/,<<'EOT');
Just some stuff from `fortune'.

live lively liver

I am not a politician and my other habits are also good.
Almost everything in life is easier to get into than out of.
The reward of a thing well done is to have done it.
/earth is 98% full ... please delete anyone you can.
Hoping to goodness is not theologically sound. - Peanuts
There is a Massachusetts law requiring all dogs to have
their hind legs tied during the month of April.
The man scarce lives who is not more credulous than he ought to be.... The
natural disposition is always to believe.  It is acquired wisdom and experience
only that teach incredulity  and they very seldom teach it enough.
- Adam Smith
Kansas state law requires pedestrians crossing the highways at night to
wear tail lights.
Very few things actually get manufactured these days  because in an
infinitely large Universe  such as the one in which we live  most things one
could possibly imagine  and a lot of things one would rather not  grow
somewhere.  A forest was discovered recently in which most of the trees grew
ratchet screwdrivers as fruit.  The life cycle of the ratchet screwdriver is
quite interesting.  Once picked it needs a dark dusty drawer in which it can
lie undisturbed for years.  Then one night it suddenly hatches  discards its
outer skin that crumbles into dust  and emerges as a totally unidentifiable
little metal object with flanges at both ends and a sort of ridge and a hole
for a screw.  This  when found  will get thrown away.  No one knows what the
screwdriver is supposed to gain from this.  Nature  in her infinite wisdom 
is presumably working on it.
EOT

    ##
    # The algorithm below gives us 201 distinct shorts, 287 distinct
    # longs and 300 distinct pairs
    #
    my $n=1;
    my $ns=2;
    my $nl=3;
    my $pp=12;
    $customer->put(name => 'Search Test Customer');
    for(1..300) {
        my $str='';
        for(my $i=0; $i!=10; $i++) {
            $str.=' ' if $str;
            $str.=$words[$ns];
            $ns+=7+$n;
            $ns-=200 while $ns>=200;
        }
        $customer->put(short => $str);
        $str='';
        for(my $i=0; $i!=50; $i++) {
            $str.=' ' if $str;
            $str.=$words[$nl];
            $nl+=11+$n;
            $nl-=@words while $nl>=@words;
        }
        $customer->put(long => $str);
        my $id=$custlist->put($customer);
        $n++;

        my $plist=$custlist->get($id)->get('Products');
        $product->put(price => $pp);
        $pp+=17.21;
        $pp-=1000 if $pp>=1000;
        $plist->put($product);
    }

    ##
    # Checking normal search
    #
    my $list=$custlist->search('short', 'ws', 'live');
    $self->assert(@$list == 43,
                  "Wrong search results, test 1 (".scalar(@$list).")");
    $list=$custlist->search([ 'short', 'wq', 'have' ],
                            'and',
                            [ 'long', 'ws', 'thing' ]);
    $self->assert(@$list == 19,
                  "Wrong search results, test 2 (".scalar(@$list).")");
    $list=$custlist->search([ 'short', 'wq', 'in' ],
                            'or',
                            [ 'long', 'wq', 'the' ]);
    $self->assert(@$list == 233,
                  "Wrong search results, test 3 (".scalar(@$list).")");
    $list=$custlist->search([ 'short', 'wq', 'is|not' ],
                            'or',
                            [ 'long', 'wq', '[aA]' ]);
    $self->assert(@$list == 0,
                  "Wrong search results, test 16 (".scalar(@$list).")");

    ##
    # Checking multiple keyword search
    #
    $list=$custlist->search('short', 'wq', [qw(in the forest)] );
    $self->assert(@$list == 192,
                  "Wrong search results, test 4 (".scalar(@$list).")");
    $list=$custlist->search([ 'short', 'wq', 'in' ],
                            'OR',
                            [ [ 'short', 'wq', 'the' ],
                              'OR',
                              [ 'short', 'wq', 'forest' ]
                            ]);
    $self->assert(@$list == 192,
                  "Wrong search results, test 5 (".scalar(@$list).")");

    ##
    # Check sorting
    #
    $list=$custlist->search([ 'short', 'wq', 'in' ],
                            'and',
                            [ 'long', 'wq', 'the' ],
                            { orderby => [ ascend => 'short',
                                           ascend => 'long' ]
                            });
    $self->assert(@$list == 61,
                  "Wrong search results, test 6 (".scalar(@$list).")");
    my $short;
    my $long;
    foreach my $id (@$list) {
        my $obj=$custlist->get($id);
        my $s=$obj->get('short');
        my $l=$obj->get('long');
        next unless $s =~ /^[a-z]/ && $l =~ /^[a-z]/;
        if($short && $long) {
            $self->assert(ord($s) >= ord($short),
                          "Wrong sorting order ('$s' < '$short')");
            if($s eq $short) {
                $self->assert(ord($l) >= ord($long),
                              "Wrong sorting order ('$l' < '$long')");
            }
        }
        else {
            $short=$s;
            $long=$l;
        }
    }

    ##
    # Check reverse sorting and passing array reference at the same
    # time.
    #
    $list=$custlist->search([ [ 'short', 'wq', 'in' ],
                              'and',
                              [ 'long', 'wq', 'the' ],
                            ],
                            { orderby => [ descend => 'long',
                                           descend => 'short' ]
                            });
    $self->assert(@$list == 61,
                  "Wrong search results, test 15 (".scalar(@$list).")");
    $short=undef;
    $long=undef;
    foreach my $id (@$list) {
        my $obj=$custlist->get($id);
        my $s=$obj->get('short');
        my $l=$obj->get('long');
        next unless $s =~ /^[a-z]/ && $l =~ /^[a-z]/;
        if($short && $long) {
            $self->assert(ord($l) <= ord($long),
                          "Wrong sorting order ('$l' > '$long')");
            if($l eq $long) {
                $self->assert(ord($s) <= ord($short),
                              "Wrong sorting order ('$s' > '$short')");
            }
        }
        else {
            $short=$s;
            $long=$l;
        }
    }

    ##
    # Check how distinct works
    #
    $list=$custlist->search('short', 'wq', 'you', { distinct => 'short' });
    $self->assert(@$list == 18,
                  "Wrong search results, test 7 (".scalar(@$list).")");
    $list=$custlist->search('short', 'wq', [qw(seldom dogs)],
                            { distinct => 'long' });
    $self->assert(@$list == 29,
                  "Wrong search results, test 8 (".scalar(@$list).")");
    $list=$custlist->search('short', 'wq', [qw(you the in at to)],
                            { distinct => [qw(short long)] });
    $self->assert(@$list == 235,
                  "Wrong search results, test 9 (".scalar(@$list).")");

    ##
    # Finally, checking how empty condition works
    #
    $list=$custlist->search();
    $self->assert(@$list == 302,
                  "Wrong search results, test 10 (".scalar(@$list).")");

    ##
    # Check ordering works on empty conditions.
    #
    $list=$custlist->search({ orderby => [ ascend => 'short',
                                           descend => 'long' ]
                            });
    $self->assert(@$list == 302,
                  "Wrong search results, test 11 (".scalar(@$list).")");
    $short=undef;
    $long=undef;
    foreach my $id (@$list) {
        my $obj=$custlist->get($id);
        my $s=$obj->get('short');
        my $l=$obj->get('long');
        next unless $s && $s =~ /^[a-z]/ && $l =~ /^[a-z]/;
        if($short && $long) {
            $self->assert(ord($s) >= ord($short),
                          "Wrong sorting order ('$s' < '$short')");
            if($s eq $short) {
                $self->assert(ord($l) <= ord($long),
                              "Wrong sorting order ('$l' > '$long')");
            }
        }
        else {
            $short=$s;
            $long=$l;
        }
    }

    ##
    # Now checking how ordering on inner property works
    #
    $list=$custlist->search({ orderby => [ ascend => 'Products/price',
                                           descend => 'short' ]
                            });
    $self->assert(@$list == 300,
                  "Wrong search results, test 12 (".scalar(@$list).")");
    $short=undef;
    my $price=undef;
    foreach my $id (@$list) {
        my $obj=$custlist->get($id);
        my $s=$obj->get('short');
        next unless $s && $s =~ /^[a-z]/;
        my $pl=$obj->get('Products');
        my $p=$pl->get(($pl->keys)[0])->get('price');
        if($short && defined($price)) {
            $self->assert($p >= $price,
                          "Wrong sorting order ($p < $price)");
            if($p == $price) {
                dprint "That happened ($p)";
                $self->assert(ord($s) <= ord($short),
                              "Wrong sorting order ('$s' > '$short')");
            }
        }
        else {
            $short=$s;
            $price=$p;
        }
    }

    ##
    # Searching by price and checking that IDs in this simple case are
    # distinct.
    #
    $list=$custlist->search([ 'Products/price', 'gt', 100 ],
                            'and',
                            [ 'Products/price', 'lt', 600 ]);
    $self->assert(@$list == 149,
                  "Wrong search results, test 13 (".scalar(@$list).")");
    my %a;
    @a{@$list}=@$list;
    $self->assert(scalar(keys %a) == 149,
                  "Non-unique ID in search results, test 14");


    ##
    # Cleaning up
    #
    $customer->drop_placeholder('long');
    $customer->drop_placeholder('short');
}

sub test_collection_search {
    my $self=shift;
    my $odb=$self->get_odb();

    my $cc=$odb->collection(class => 'Data::Customer');

    my $list=$cc->search('name', 'wq', 'Test');

    $self->assert(@$list == 2,
                  "Search results are wrong on collection");
}

##
# See note in CHANGES for 1.03 for the bug we're testing here against.
# First think to do if that test ever fails again is to uncomment
# printing final SQL statement in Glue.pm and check if table joins are
# correct.
# am@xao.com, Jan/18, 2002
#
sub test_multiple_branches {
    my $self=shift;
    my $odb=$self->get_odb();

    my $customers=$odb->fetch('/Customers');

    my $c=$customers->get_new;
    $c->build_structure(
        Orders => {
            type        => 'list',
            class       => 'Data::Order',
            key         => 'order_id',
            structure   => {
                name => {
                    type    => 'text',
                },
            },
        },
        Products => {
            type        => 'list',
            class       => 'Data::Product',
            key         => 'product_id',
            structure   => {
                name => {
                    type    => 'text',
                },
            },
        },
    );

    $customers->put('screw' => $c);
    $c=$customers->get('screw');
    $c->get('Orders')->put(aaa => $c->get('Orders')->get_new);
    $c->get('Orders')->get('aaa')->put(name => 'foo');
    $c->get('Products')->put(bbb => $c->get('Products')->get_new);
    $c->get('Products')->get('bbb')->put(name => 'bar');

    $c=$customers->get('c1');
    $c->get('Orders')->put(ooo => $c->get('Orders')->get_new);
    $c->get('Orders')->get('ooo')->put(name => 'foo');
    $c->get('Products')->put(ppp => $c->get('Products')->get_new);
    $c->get('Products')->get('ppp')->put(name => 'bar');

    $c=$customers->get('c2');
    $c->get('Orders')->put(ooo => $c->get('Orders')->get_new);
    $c->get('Orders')->get('ooo')->put(name => 'ku');
    $c->get('Products')->put(ppp => $c->get('Products')->get_new);
    $c->get('Products')->get('ppp')->put(name => 'ru');

    $customers->put(c3 => $customers->get_new);
    $c=$customers->get('c3');
    $c->get('Orders')->put(ooo => $c->get('Orders')->get_new);
    $c->get('Orders')->get('ooo')->put(name => 'boom');
    $c->get('Products')->put(ppp => $c->get('Products')->get_new);
    $c->get('Products')->get('ppp')->put(name => 'ru');

    $customers->put(c4 => $customers->get_new);
    $c=$customers->get('c4');
    $c->get('Orders')->put(ooo => $c->get('Orders')->get_new);
    $c->get('Orders')->get('ooo')->put(name => 'ku');
    $c->get('Products')->put(ppp => $c->get('Products')->get_new);
    $c->get('Products')->get('ppp')->put(name => 'duh!');

    my $ids=$customers->search([ 'Products/name', 'eq', 'ku' ],
                               'or',
                               [ 'Orders/name', 'eq', 'ru' ],
                               { orderby => 'customer_id' });

    my $t_ids=join(",",@$ids);
    $self->assert($t_ids eq '',
                  "Wrong search results for multi-branch search (got '$t_ids', expect '')");

    $ids=$customers->search([ 'Orders/name', 'eq', 'ku' ],
                            'or',
                            [ 'Products/name', 'eq', 'ru' ],
                            { orderby => 'customer_id' });

    $t_ids=join(",",@$ids);
    $self->assert($t_ids eq 'c2,c3,c4',
                  "Wrong search results for multi-branch search (got '$t_ids', expect 'c2,c3,c4')");

    $ids=$customers->search([ 'Orders/name', 'eq', 'kaaau' ],
                            'or',
                            [ 'Products/name', 'eq', 'ru' ],
                            { orderby => 'customer_id' });

    $t_ids=join(",",@$ids);
    $self->assert($t_ids eq 'c2,c3',
                  "Wrong search results for multi-branch search (got '$t_ids', expect 'c2,c3')");

    $ids=$customers->search([ 'Orders/name', 'eq', 'foo' ],
                            'and',
                            [ 'Products/name', 'eq', 'bar' ]);

    $t_ids=join(",",@$ids);
    $self->assert($t_ids eq 'c1,screw',
                  "Wrong search results for multi-branch search (got '$t_ids', expect 'c1,screw')");
}

1;
