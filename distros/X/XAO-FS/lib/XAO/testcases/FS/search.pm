package XAO::testcases::FS::search;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(XAO::testcases::FS::base);

###############################################################################

### This bug is known, there is no easy fix for it. And I am not sure it should be fixed at all.

### sub test_mixed_levels {
###     my $self=shift;
###     my $odb=$self->get_odb();
###
###     $odb->fetch('/')->build_structure(
###         Level0 => {
###             type        => 'list',
###             class       => 'Data::Level0',
###             key         => 'l0_id',
###             structure   => {
###                 Level1 => {
###                     type        => 'list',
###                     class       => 'Data::Level1',
###                     key         => 'l1_id',
###                     structure   => {
###                         text => {
###                             type        => 'text',
###                             maxlength   => 50,
###                         },
###                     },
###                 },
###                 text => {
###                     type        => 'text',
###                     maxlength   => 50,
###                 },
###             },
###         },
###     );
###
###     my ($l0_obj,$l1_obj);
###     my ($l0_list,$l1_list);
###     my $obj_id;
###
###     #1st elt has no 1st level list
###     $l0_list=$odb->fetch('/Level0');
###     $l0_obj=$l0_list->get_new();
###     $l0_obj->put(text=>'foobar');
###     $obj_id=$l0_list->put($l0_obj);
### # If you uncomment this lines, search will be ok
### # but with empty 1-st level list, search unable to find first record with text='foobar'
### #    $l0_obj=$l0_list->get($obj_id);
### #    my $l1_list=$l0_obj->get('Level1');
### #    $l1_obj=$l1_list->get_new();
### #    $l1_obj->put(text=>'zzz');
### #    $l1_list->put($l1_obj);
###
###     #2nd elt has 1st level branch with 2 records ('foo','bar');
###     $l0_obj=$l0_list->get_new();
###     $l0_obj->put(text=>'something different');
###     $obj_id=$l0_list->put($l0_obj);
###     $l0_obj=$l0_list->get($obj_id);
###     $l1_list=$l0_obj->get('Level1');
###     $l1_obj=$l1_list->get_new();
###     $l1_obj->put(text=>'foo');
###     $l1_list->put($l1_obj);
###     $l1_obj=$l1_list->get_new();
###     $l1_obj->put(text=>'bar');
###     $l1_list->put($l1_obj);
###
###     my $sr=$l0_list->search(
###         [
###             ['text','cs','bar'],
###             'or',
###             ['Level1/text','cs','bar'],
###         ],
###     );
###
###     my $nrows=scalar(@$sr);
###     $self->assert($nrows==2,
###         "Wrong search results in test_mixed_levels ($nrows instead of 2)");
### }

###############################################################################

sub test_scan {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust_list=$odb->fetch('/Customers');
    my $cust_obj=$cust_list->get_new();

    for(my $i=0; $i<100; ++$i) {
        $cust_obj->put(name => sprintf('scancust%04u',$i));
        $cust_list->put(sprintf('id%04u',$i) => $cust_obj);
    }

    $self->assert(scalar($cust_list->keys)==102,
                  "Expected to have 102 customers in the list, got ".scalar($cust_list->keys));


    my %tests=(
        t01 => {
            params  => {
                block_size => 20,
                search_query  => [
                    'name','sw','scancust',
                ],
                search_options => {
                    result  => [ 'customer_id','name' ],
                    orderby => [ descend => 'customer_id' ],
                    limit   => 90,  # overall limit
                    offset  => 5,   # overall offset
                },
            },
            expect => {
                rows    => 90,
                blocks  => 5,
                first5  => 'id0094,id0093,id0092,id0091,id0090',
            },
        },
        t02 => {
            params  => {
                block_size => 1,
                search_query  => [
                    'name','sw','scancust',
                ],
                search_options => {
                    orderby => 'name',
                },
            },
            expect => {
                rows    => 100,
                blocks  => 100,
                first5  => 'id0000,id0001,id0002,id0003,id0004',
            },
        },
        t03 => {
            params  => {
                block_size => 11,
                search_options => {
                    orderby => 'customer_id',
                    offset  => 5,   # overall offset
                },
            },
            expect => {
                rows    => 97,
                blocks  => 9,
                first5  => 'id0003,id0004,id0005,id0006,id0007',
            },
        },
        t04 => {
            params  => {
                block_size  => 40,
                limit       => 35,  # overall offset
                search_options => {
                    orderby => 'customer_id',
                    limit   => 50,  # low priority
                },
            },
            expect => {
                rows    => 35,
                blocks  => 1,
                first5  => 'c1,c2,id0000,id0001,id0002',
            },
        },
    );

    # Testing both collection and list scanning on the same set of tests.
    #
    my $cust_coll=$odb->collection(class => 'Data::Customer');

    foreach my $cust_lc ($cust_list,$cust_coll) {
        foreach my $testname (keys %tests) {
            my $tdata=$tests{$testname};

            my $called_before=0;
            my $called_block=0;
            my $called_row=0;
            my $called_after=0;
            my @srb;
            my @srr;
            $cust_lc->scan($tdata->{'params'},{
                call_before => sub {
                    my ($list,$args)=@_;
                    ++$called_before;
                    $self->assert(ref($args) && $args->{'block_size'},
                                  "Expected to get back arguments in 'call_before'");
                    $self->assert(ref($list),
                                  "Expected to get back list in 'call_before'");
                },
                call_block => sub {
                    my ($list,$args,$block)=@_;
                    ++$called_block;
                    ### dprint "call_block($called_block): ".Dumper($block);
                    push(@srb,@$block);
                    $self->assert((ref($args) && ref($args->{'call_block'})) ? 1 : 0,
                                  "$testname: Expected to get back arguments in 'call_block'");
                    $self->assert((ref($list)) ? 1 : 0,
                                  "$testname: Expected to get back list in 'call_block'");
                    $self->assert(ref($block) eq 'ARRAY',
                                  "$testname: Expected to get results block in 'call_block'");
                },
                call_row => sub {
                    my ($list,$args,$row)=@_;
                    ++$called_row;
                    push(@srr,$row);
                    $self->assert((ref($args) && $args->{'search_options'}) ? 1 : 0,
                                  "$testname: Expected to get back arguments in 'call_row'");
                    $self->assert(ref($list),
                                  "$testname: Expected to get back list in 'call_row'");
                    $self->assert(defined($row),
                                  "$testname: Expected to get a result row in 'call_row'");
                },
                call_after => sub {
                    my ($list,$args)=@_;
                    ++$called_after;
                    $self->assert(ref($args) && $args->{'block_size'},
                                  "$testname: Expected to get back arguments in 'call_after'");
                    $self->assert(ref($list),
                                  "$testname: Expected to get back list in 'call_after'");
                },
            });

            my $expect=$tdata->{'expect'};

            $self->assert($called_before==1,
                          "$testname: Expected to have called_before==1, got $called_before");
            $self->assert($called_block==$expect->{'blocks'},
                          "$testname: Expected to have called_block==$expect->{'blocks'}, got $called_block");
            $self->assert($called_row==$expect->{'rows'},
                          "$testname: Expected to have called_row==$expect->{'rows'}, got $called_row");
            $self->assert($called_after==1,
                          "$testname: Expected to have called_after==1, got $called_after");

            $self->assert(scalar(@srb)==scalar(@srr),
                          "$testname: Expected to have the same data from call_block and call_row");
            for(my $i=0; $i<@srr; ++$i) {
                $self->assert($srb[$i] eq $srr[$i],
                              "$testname: Expected to have the same data from call_block and call_row, got $srb[$i] and $srr[$i] at position $i");
            }

            # In the collection we're going to get collection IDs, not list
            # IDs. Translating them to make the same tests work in both
            # cases.
            #
            @srr=(map { ref($_) ? $_ : $cust_lc->get($_)->container_key } @srr);

            my $first5=join(',',map { ref($_) ? $_->[0] : $_ } @srr[0..4] );

            $self->assert($first5 eq $expect->{'first5'},
                          "$testname: Expected first 5 elements to be $expect->{'first5'}, got $first5");
        }
    }
}

###############################################################################

sub test_mixed_case {
    my $self=shift;

    my $odb=$self->get_odb();

    my $custlist=$odb->fetch('/Customers');

    my $customer=$custlist->get_new();

    $self->assert(ref($customer),
                  "Can't create Customer");

    $customer->add_placeholder(
        name        => 'MixedCase',
        type        => 'text',
        charset     => 'utf8',  # required for case-ign. collation
        maxlength   => 100,
        index       => 1,
    );

    $customer->add_placeholder(
        name        => 'lowFirst',
        type        => 'text',
        charset     => 'latin1',
        maxlength   => 1000,
    );

    $customer->put(
        MixedCase       => 'mixed1',
        lowFirst        => 'lc1',
    );
    $custlist->put(mct1 => $customer);
    $customer->put(
        MixedCase       => 'mixed2 with more',
        lowFirst        => 'lc2',
    );
    $custlist->put(mct2 => $customer);

    my $sr=$custlist->search('MixedCase','eq','mixed1');
    $self->assert(@$sr==1,
                  "Expected 1 result for mixed1");
    $self->assert($sr->[0] eq 'mct1',
                  "Expected to find 'mct1' for 'mixed1'");

    $sr=$custlist->search('MixedCase','sw','mixed');
    $self->assert(@$sr==2,
                  "Expected 2 results for mixed1");

    $sr=$custlist->search('lowFirst','eq','lc2');
    $self->assert(@$sr==1,
                  "Expected 1 result for lowFirst=lc2");
    $self->assert($sr->[0] eq 'mct2',
                  "Expected to find 'mct2' for 'lc2'");

    $sr=$custlist->search(['lowFirst','eq','lc2'],'and',['MixedCase','eq','mixed1']);
    $self->assert(@$sr==0,
                  "Expected NO result for [lowFirst=lc2] and [MixedCase=mixed1]");
}

###############################################################################

# Testing how returning multiple fields works -- 'result' option in search

sub test_result_option {
    my $self=shift;
    my $odb=$self->get_odb();

    my $cust_list=$odb->fetch('/Customers');

    $cust_list->get_new->add_placeholder(
        name        => 'desc',
        type        => 'text',
        maxlength   => 50,
        charset     => 'utf8',
    );
    $cust_list->get_new->add_placeholder(
        name        => 'common',
        type        => 'text',
        maxlength   => 50,
        charset     => 'utf8',
    );
    $cust_list->get('c1')->put(name => 'name1', desc => 'aaaaa', common => 'common');
    $cust_list->get('c2')->put(name => 'name2', desc => 'ddddd', common => 'common');

    $cust_list->get_new->add_placeholder(
        name        => 'Orders',
        type        => 'list',
        class       => 'Data::Order',
        key         => 'order_id',
    );
    my $order_list=$cust_list->get('c1')->get('Orders');
    my $order_obj=$order_list->get_new;
    $order_obj->add_placeholder(
        name        => 'total',
        type        => 'real',
    );
    $order_obj->add_placeholder(
        name        => 'text',
        type        => 'text',
        maxlength   => 100,
    );
    $order_obj->put(
        total       => 123.45,
        text        => 'c1o1',
    );
    $order_list->put('o1' => $order_obj);
    $order_obj->put(
        total       => 234.56,
        text        => 'c1o2',
    );
    $order_list->put('o2' => $order_obj);
    $order_obj->put(
        total       => 345.67,
        text        => 'c1o3',
    );
    $order_list->put('o3' => $order_obj);
    $order_list=$cust_list->get('c2')->get('Orders');
    $order_obj->put(
        total       => 456.78,
        text        => 'c2o1',
    );
    $order_list->put('o1' => $order_obj);
    $order_obj->put(
        total       => 567.89,
        text        => 'c2o2',
    );
    $order_list->put('o2' => $order_obj);

    my $order_coll=$odb->collection(class => 'Data::Order');

    my %matrix=(
        t01 => {
            list    => $cust_list,
            args    => [ 'desc','cs','d' ],
            options => { result => [ qw(name desc) ], orderby => '-name', distinct => 'customer_id' },
            result  => 'name2|ddddd',
            rcount  => 2,
        },
        t02 => {
            list    => $cust_list,
            options => { result => [ qw(desc) ], orderby => 'name' },
            result  => 'aaaaa;ddddd',
            rcount  => 1,
        },
        t03 => {
            list    => $cust_list,
            args    => [ 'desc','cs','a' ],
            options => { result => [ '#container_key','customer_id','name','desc' ], orderby => '-name' },
            result  => 'c1|c1|name1|aaaaa',
            rcount  => 4,
        },
        t04 => {
            list    => $cust_list,
            options => { result => [ '#collection_key' ], orderby => 'desc' },
            result  => '1;2',         # this may break in other databases
            rcount  => 1,
        },
        t05 => {
            list    => $order_coll,
            options => { result => [ '#id' ], orderby => 'text' },
            result  => '1;2;3;4;5',     # this may break in other databases
        },
        t06 => {
            list    => $cust_list,
            options => { result => [ qw(common common) ], distinct => 'common' },
            result  => 'common|common',
        },
        t07 => {
            list    => $order_coll,
            options => { result => [ '#connector', 'parent_unique_id' ] },
            result  => sub {
                my $row=shift;
                $self->assert($row->[0] eq $row->[1],
                    "Expected #connector value '$row->[0]' to equal parent_unique_id value '$row->[1]'");
            },
        },
        t10 => {
            list    => $cust_list,
            args    => [ 'Orders/total','gt',300 ],
            options => { result => [ qw(name common) ], orderby => 'customer_id' },
            result  => 'name1|common;name2|common',
            rcount  => 2,
        },
        t11 => {
            list    => $cust_list,
            args    => [ 'Orders/total','gt',300 ],
            options => { result => [ qw(Orders/total Orders/text) ],
                         orderby => [ ascend => 'customer_id', descend => 'Orders/total' ] },
            result  => '345.67|c1o3;456.78|c2o1',
            rcount  => 2,
        },
        t12 => {
            list    => $cust_list,
            options => { result => [ qw(Orders/total desc Orders/text) ],
                         orderby => '-Orders/total' },
            result  => '456.78|ddddd|c2o1;123.45|aaaaa|c1o1',
            rcount  => 3,
        },
        t13 => {
            list    => $cust_list,
            options => { result => [ qw(Orders/total customer_id Orders/text) ],
                         orderby => '-Orders/total' },
            result  => '456.78|c2|c2o1;123.45|c1|c1o1',
            rcount  => 3,
        },
        t14 => {
            list    => $cust_list,
            options => { result => [ qw(Orders/total customer_id Orders/text) ],
                         orderby => '-Orders/total',
                         distinct => 'Orders/text' },
            result  => '567.89|c2|c2o2;456.78|c2|c2o1;345.67|c1|c1o3;234.56|c1|c1o2;123.45|c1|c1o1',
            rcount  => 3,
        },
        t15 => {
            list    => $cust_list,
            options => { result => [ qw(Orders/total customer_id) ],
                         orderby => 'Orders/total',
                         distinct => 'Orders/text' },
            result  => '123.45|c1;234.56|c1;345.67|c1;456.78|c2;567.89|c2',
            rcount  => 2,
        },
        t20 => {
            list    => $order_coll,
            options => { result => [ 'text','../name','#container_key' ],
                         orderby => '-total' },
            result  => 'c2o2|name2|o2;c2o1|name2|o1;c1o3|name1|o3;c1o2|name1|o2;c1o1|name1|o1',
            rcount  => 3,
        },
        t21 => {
            list    => $cust_list,
            options => { result => [ 'common' ] },
            result  => 'common;common',
            rcount  => 1,
        },
        t22 => {
            list    => $cust_list,
            args    => [ 'Orders/total', 'gt', 0 ],
            options => { result => [ 'common' ] },
            result  => 'common;common',
            rcount  => 1,
        },
        t30 => {
            list    => $order_list,
            args    => [ [ 'total','gt',0 ], 'and', [ 'total','lt',1000 ] ],
            options => { result => [ qw(order_id text total) ],
                         orderby => 'text' },
            result  => 'o1|c2o1|456.78;o2|c2o2|567.89',
            rcount  => 3,
        }
    );

    foreach my $t (sort keys %matrix) {
        my $test=$matrix{$t};
        my $list=$test->{'list'};

        my $sr=$test->{'args'} ? $list->search($test->{'args'},$test->{'options'})
                               : $list->search($test->{'options'});

        ### dprint Dumper($sr);
        $self->assert(ref($sr) eq 'ARRAY',
                      "Test '$t', expected to get a list reference, got '".ref($sr)."'");

        $self->assert(ref($sr->[0]) eq 'ARRAY',
                      "Test '$t', expected to get a list of arrays, got '".ref($sr->[0])."'");

        my $expect=$test->{'result'};

        if(ref $expect eq 'CODE') {
            foreach my $row (@$sr) {
                $expect->($row);
            }
        }
        else {
            my $got=join(';',map {
                join('|',$test->{'rcount'} ? @$_[0..($test->{'rcount'}-1)] : @$_);
            } @$sr);

            $self->assert($got eq $expect,
                        "Test '$t', expected '$expect', got '$got'");
        }
    }
}

###############################################################################

# reported by enn@, 2006/05/03

sub test_empty_array_ref {
    my $self=shift;
    my $odb=$self->get_odb();
    my $customers=$odb->fetch('/Customers');

    my $got;
    try {
        my $sr=$customers->search([ 'name','sw', [ ] ]);
        my $got=join(',',sort @$sr);
    }
    otherwise {
        my $e=shift;
        dprint "Expected error: $e";
    };

    $self->assert(!defined $got,
                  "Bug in empty array reference treatment");
}

##################################################################################

# Test for a bug in MySQL_DBI driver in handling on multi-value returns
# in search.

sub test_bug_20030505 {
    my $self=shift;
    my $odb=$self->get_odb();
    my $customers=$odb->fetch('/Customers');
    my $sr=$customers->search({distinct => 'name'});
    my $got=join(',',sort @$sr);
    my $expect='c1,c2';
    $self->assert($got eq $expect,
                  "Bug in multi-value handling - expected $expect, got $got");
}

##
# Really deep searches that are very unlikely to ever be requested in
# real life.
#
sub test_real_deep {
    my $self=shift;

    my $odb=$self->get_odb();

    @XAO::DO::Data::A::ISA='XAO::DO::FS::Hash';
    $INC{'XAO/DO/Data/A.pm'}='XAO/DO/FS/Hash.pm';
    @XAO::DO::Data::B::ISA='XAO::DO::FS::Hash';
    $INC{'XAO/DO/Data/B.pm'}='XAO/DO/FS/Hash.pm';
    @XAO::DO::Data::C::ISA='XAO::DO::FS::Hash';
    $INC{'XAO/DO/Data/C.pm'}='XAO/DO/FS/Hash.pm';
    @XAO::DO::Data::D::ISA='XAO::DO::FS::Hash';
    $INC{'XAO/DO/Data/D.pm'}='XAO/DO/FS/Hash.pm';
    @XAO::DO::Data::E::ISA='XAO::DO::FS::Hash';
    $INC{'XAO/DO/Data/E.pm'}='XAO/DO/FS/Hash.pm';
    @XAO::DO::Data::F::ISA='XAO::DO::FS::Hash';
    $INC{'XAO/DO/Data/F.pm'}='XAO/DO/FS/Hash.pm';
    @XAO::DO::Data::G::ISA='XAO::DO::FS::Hash';
    $INC{'XAO/DO/Data/G.pm'}='XAO/DO/FS/Hash.pm';
    @XAO::DO::Data::X::ISA='XAO::DO::FS::Hash';
    $INC{'XAO/DO/Data/X.pm'}='XAO/DO/FS/Hash.pm';

    dprint "Building structure";

    $odb->fetch('/')->build_structure(
        X => {
            type        => 'list',
            class       => 'Data::X',
            key         => 'x_id',
            structure   => {
                A => {
                    type        => 'list',
                    class       => 'Data::A',
                    key         => 'a_id',
                    structure   => {
                        B => {
                            type        => 'list',
                            class       => 'Data::B',
                            key         => 'b_id',
                            structure   => {
                                C => {
                                    type        => 'list',
                                    class       => 'Data::C',
                                    key         => 'c_id',
                                    structure   => {
                                        name => {
                                            type        => 'text',
                                            maxlength   => 50,
                                        },
                                        desc => {
                                            type        => 'text',
                                            maxlength   => 300,
                                        },
                                    },
                                },
                                name => {
                                    type        => 'text',
                                    maxlength   => 50,
                                },
                                desc => {
                                    type        => 'text',
                                    maxlength   => 300,
                                },
                            },
                        },
                        name => {
                            type        => 'text',
                            maxlength   => 50,
                            index       => 1,
                        },
                        desc => {
                            type        => 'text',
                            maxlength   => 300,
                        },
                    },
                },
                D => {
                    type        => 'list',
                    class       => 'Data::D',
                    key         => 'd_id',
                    structure   => {
                        E => {
                            type        => 'list',
                            class       => 'Data::E',
                            key         => 'e_id',
                            structure   => {
                                name => {
                                    type        => 'text',
                                    maxlength   => 50,
                                    charset     => 'latin1',
                                },
                                desc => {
                                    type        => 'text',
                                    maxlength   => 300,
                                    charset     => 'utf8',
                                },
                            },
                        },
                        name => {
                            type        => 'text',
                            maxlength   => 50,
                            index       => 1,
                            unique      => 1,
                        },
                        desc => {
                            type        => 'text',
                            maxlength   => 300,
                        },
                    },
                },
                F => {
                    type        => 'list',
                    class       => 'Data::F',
                    key         => 'f_id',
                    structure   => {
                        G => {
                            type        => 'list',
                            class       => 'Data::G',
                            key         => 'g_id',
                            structure   => {
                                name => {
                                    type        => 'text',
                                    maxlength   => 50,
                                },
                                desc => {
                                    type        => 'text',
                                    maxlength   => 300,
                                },
                            },
                        },
                        name => {
                            type        => 'text',
                            maxlength   => 50,
                        },
                        desc => {
                            type        => 'text',
                            maxlength   => 300,
                        },
                    },
                },
                name => {
                    type        => 'text',
                    maxlength   => 50,
                },
                desc => {
                    type        => 'text',
                    maxlength   => 300,
                },
            },
        },
    );

    srand(876543);
    if(int(rand(1000))!=838) {
        print STDERR "Got incompatible random sequence, skipping the test\n";
        return;
    }
    srand(876543);

    dprint "Structure done, filling up..";
    my @wordlist=qw(qwe wer ert rty tyu yui uio iop op[ p[] []\
                    asdf sdfg dfgh fghj ghjk hjkl jkl; kl;'
                    zxcvb xcvbn cvbnm vbnm bnm. nm./
                    qwerty wertyu ertui adsfa awerq adf qtwt ljl
                    qwer qw);
    my $rname=sub {
        my $name='';
        for(1..5) {
            $name.=' ' if $name;
            $name.=$wordlist[rand(@wordlist)];
        }
        return substr($name,0,50);
    };
    my $rdesc=sub {
        my $name='';
        for(1..20) {
            $name.=' ' if $name;
            $name.=$wordlist[rand(@wordlist)];
        }
        return substr($name,0,300);
    };

    my $xlist=$odb->fetch('/X');
    my $xnew=$xlist->get_new;
    my $on='a001';
    for(1..5) {
        $xnew->put(
            name    => &$rname,
            desc    => &$rdesc,
        );
        my $xid=$on++;
        $xlist->put($xid => $xnew);
        ## dprint ".xid=$xid";
        my $xobj=$xlist->get($xid);
        my $alist=$xobj->get('A');
        my $anew=$alist->get_new;
        for(1..5) {
            $anew->put(
                name    => &$rname,
                desc    => &$rdesc,
            );
            my $aid=$on++;
            $alist->put($aid => $anew);
            ## dprint "..aid=$aid";
            my $aobj=$alist->get($aid);
            my $blist=$aobj->get('B');
            my $bnew=$blist->get_new;
            for(1..5) {
                $bnew->put(
                    name    => &$rname,
                    desc    => &$rdesc,
                );
                my $bid=$on++;
                $blist->put($bid => $bnew);
                ## dprint "...bid=$bid";
                my $bobj=$blist->get($bid);
                my $clist=$bobj->get('C');
                my $cnew=$clist->get_new;
                for(1..5) {
                    $cnew->put(
                        name    => &$rname,
                        desc    => &$rdesc,
                    );
                    my $cid=$on++;
                    $clist->put($cid => $cnew);
                    ## dprint "....cid=$cid";
                    my $cobj=$clist->get($cid);
                }
            }
        }
        my $dlist=$xobj->get('D');
        my $dnew=$dlist->get_new;
        for(1..5) {
            $dnew->put(
                name    => &$rname,
                desc    => &$rdesc,
            );
            my $did=$on++;
            $dlist->put($did => $dnew);
            ## dprint "..did=$did";
            my $dobj=$dlist->get($did);
            my $elist=$dobj->get('E');
            my $enew=$elist->get_new;
            for(1..5) {
                $enew->put(
                    name    => &$rname,
                    desc    => &$rdesc,
                );
                my $eid=$on++;
                $elist->put($eid => $enew);
                ## dprint "...eid=$eid";
            }
        }
        my $flist=$xobj->get('F');
        my $fnew=$flist->get_new;
        for(1..5) {
            $fnew->put(
                name    => &$rname,
                desc    => &$rdesc,
            );
            my $fid=$on++;
            $flist->put($fid => $fnew);
            ## dprint "..fid=$fid";
            my $fobj=$flist->get($fid);
            my $glist=$fobj->get('G');
            my $gnew=$glist->get_new;
            for(1..5) {
                $gnew->put(
                    name    => &$rname,
                    desc    => &$rdesc,
                );
                my $gid=$on++;
                $glist->put($gid => $gnew);
                ## dprint "...gid=$gid";
            }
        }
    }
    dprint "Done building test data set, starting tests..";

    my %matrix=(
        t1 => {
            args    => [
                [ 'name', 'wq', 'qwerty' ],
                'and',
                [ 'desc', 'wq', 'qwerty' ],
            ],
            class   => 'Data::B',
            result  => '105,13,21,27,3,41,43,75,9',
            sort    => 1,
        },
        t2 => {
            args    => [
                [ 'name', 'wq', 'qwerty' ],
                'and',
                [ 'desc', 'wq', 'qwerty' ],
                { orderby => 'C/name' },
            ],
            class   => 'Data::B',
            result  => '9,13,21,41,43,3,27,75,105',
        },
        t3 => {
            args    => [
                [ 'C/name', 'sw', 'q' ],
                'and',
                [ '../desc', 'sw', 'w' ],
                { orderby => '/X/A/B/name' },
            ],
            class   => 'Data::B',
            result  => '108,33,106,109',
        },
        t3_1 => {
            args    => [
                [ 'C/name', 'sw', 'q' ],
                'and',
                [ '../desc', 'sw', 'w' ],
                { orderby => '/X/A/B/name',
                  index   => '../../A/name',
                },
            ],
            class   => 'Data::B',
            result  => '108,33,106,109',
        },
        t3_2 => {
            args    => [
                [ 'C/name', 'sw', 'q' ],
                'and',
                [ '../desc', 'sw', 'w' ],
                { orderby => 'C/../name',
                  index   => '../B/C/name',
                },
            ],
            class   => 'Data::B',
            result  => '108,33,106,109',
        },
        t4 => {
            args    => [
                [ [ '/X/F/G/name','sw','a' ],
                  'or',
                  [ '../../D/E/name','sw','b' ],
                ],
                'and',
                [ 'C/desc', 'sw', 'qwerty' ],
            ],
            class   => 'Data::B',
            result  => '100,109,2,27,30,71,80,84,90,91',
            sort    => 1,
        },
        t4_1 => {
            args    => [
                [ [ '/X/F/G/name','sw','a' ],
                  'or',
                  [ '../../D/E/name','sw','b' ],
                ],
                'and',
                [ 'C/desc', 'sw', 'qwerty' ],
            ],
            uri     => '/X/a001/A/a002/B',
            result  => 'a009',
            sort    => 1,
        },
        t4_2 => {
            args    => [
                [ [ '/X/F/G/name','sw','a' ],
                  'or',
                  [ '../../D/E/name','sw','b' ],
                ],
                'and',
                [ 'C/desc', 'sw', 'qwerty' ],
                { index => '/X/name',
                  orderby => '-/X/A/B/name',
                }
            ],
            uri     => '/X/a217/A/a218/B',
            result  => 'a243,a225',
        },
        t5 => {
            args    => [
                [ '/project','cs','new' ],
            ],
            uri     => '/X/a217/A/a218/B',
            result  => 'a219,a225,a231,a237,a243',
            sort    => 1,
        },
        t5_1 => {
            args    => [
                [ '/project','eq','new' ],
            ],
            uri     => '/X/a217/A/a218/B',
            result  => '',
            sort    => 1,
        },
        t6 => {
            args    => [
                [ '/project','cs','new' ],
                { orderby   => 'name',
                  limit     => 10,
                },
            ],
            class   => 'Data::E',
            result  => '14,57,23,90,103,33,105,22,80,27',
        },
        t6_1 => {
            args    => [
                [ '/project','cs','new' ],
                { orderby   => 'name',
                  limit     => 10,
                  index     => '/X/D/name',
                },
            ],
            class   => 'Data::E',
            result  => '14,57,23,90,103,33,105,22,80,27',
        },
        t6_2 => {
            args    => [
                [ '/project','cs','new' ],
                { orderby   => 'name',
                  limit     => 10,
                  offset    => 0,
                },
            ],
            class   => 'Data::E',
            result  => '14,57,23,90,103,33,105,22,80,27',
        },
        t6_3 => {
            args    => [
                [ '/project','cs','new' ],
                { orderby   => 'name',
                  limit     => 10,
                  offset    => 1,
                },
            ],
            class   => 'Data::E',
            result  => '57,23,90,103,33,105,22,80,27,74',
        },
        t6_4 => {
            args    => [
                [ '/project','cs','new' ],
                { orderby   => 'name',
                  offset    => 120,
                },
            ],
            class   => 'Data::E',
            result  => '30,19,73,65,92',
        },
        t7 => {
            args    => [
                [ 'B/*/C/*/name', 'sw', 'e' ],
                'and',
                [ 'B/*/C/*/name', 'sw', 'r' ],
            ],
            class   => 'Data::A',
            result  => '1,10,11,13,15,16,17,23,5,6,9',
            sort    => 1,
        },
        t7_1 => {
            args    => [
                [ 'B/*/C/1/name', 'sw', 'e' ],
                'and',
                [ 'B/*/C/1/name', 'sw', 'r' ],
            ],
            class   => 'Data::A',
            result  => '',
            sort    => 1,
        },
        t7_2 => {
            args    => [
                [ 'B/1/C/*/name', 'sw', 'er' ],
                'and',
                [ 'B/1/C/*/name', 'sw', 'rt' ],
            ],
            class   => 'Data::A',
            result  => '11,15,23',
            sort    => 1,
        },
        t7_3 => {
            args    => [
                [ 'B/C/*/name', 'sw', 'er' ],
                'and',
                [ 'B/C/*/name', 'sw', 'rt' ],
            ],
            class   => 'Data::A',
            result  => '11,15,23',
            sort    => 1,
        },
        t7_4 => {
            args    => [
                [ 'B/C/1/name', 'sw', 'er' ],
                'and',
                [ 'B/C/2/name', 'sw', 'rt' ],
            ],
            class   => 'Data::A',
            result  => '11,15,23',
            sort    => 1,
        },
        t7_5 => {
            args    => [
                [ 'B/3/C/1/name', 'sw', 'er' ],
                'and',
                [ 'B/3/C/1/name', 'sw', 'rt' ],
            ],
            class   => 'Data::A',
            result  => '',
            sort    => 1,
        },
    );

    foreach my $test_id (sort keys %matrix) {
        my $test_data=$matrix{$test_id};
        my $list;
        if($test_data->{class}) {
            $list=$odb->collection(class => $test_data->{class});
        }
        else {
            $list=$odb->fetch($test_data->{uri});
        }
        my $sr=$list->search(@{$test_data->{args}});
        my $got=join(",",$test_data->{sort} ? (sort @$sr) : @$sr);
        my $expect=$test_data->{result};
        $self->assert($got eq $expect,
                      "Test '$test_id' is wrong: got='$got', expect='$expect'");
    }
}

###############################################################################

sub test_search {
    my $self=shift;

    my $odb=$self->get_odb();

    my $custlist=$odb->fetch('/Customers');

    my $customer=$custlist->get_new();

    $self->assert(ref($customer),
                  "Can't create Customer");

    $customer->add_placeholder(
        name        => 'short',
        type        => 'text',
        charset     => 'utf8',  # required for case-ign. collation
        maxlength   => 100,
        index       => 1,
    );

    $customer->add_placeholder(
        name        => 'long',
        type        => 'text',
        charset     => 'utf8',
        maxlength   => 1000,
    );

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
Just some stuff from 'fortune'.

live lively liver

I am not a politician and my other habits are also good.
Almost everything in life is easier to get into than out of.
The reward of a thing well done is to have done it.
earth is 98% full ... please delete anyone you can.
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
    $odb->transact_begin;
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
    $odb->transact_commit;

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
# First thing to do if that test ever fails again is to uncomment
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
                    type        => 'text',
                    maxlength   => 100,
                },
            },
        },
        Products => {
            type        => 'list',
            class       => 'Data::Product',
            key         => 'product_id',
            structure   => {
                name => {
                    type        => 'text',
                    maxlength   => 100,
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
                            { orderby => '-customer_id' });

    $t_ids=join(",",@$ids);
    $self->assert($t_ids eq 'c3,c2',
                  "Wrong search results for multi-branch search (got '$t_ids', expect 'c3,c2')");

    $ids=$customers->search([ 'Orders/name', 'eq', 'foo' ],
                            'and',
                            [ 'Products/name', 'eq', 'bar' ],
                            { orderby => 'customer_id' });

    $t_ids=join(",",@$ids);
    $self->assert($t_ids eq 'c1,screw',
                  "Wrong search results for multi-branch search (got '$t_ids', expect 'c1,screw')");
}

##
# Imagine a structure like this:
#  /Orders
#   |-o1
#   | |-Products
#   | | |-p1
#   | | | |-min => 100
#   | | | \-max => 200
#   | | |-p2
#   | | | |-min => 150
#   | | | \-max => 250
#
# What should be returned by:
#  $orders->search([ 'Products/min','eq',100 ], 'and',
#                  [ 'Products/max','eq',250 ]);
# Should the 'o1' match? Now there is a way to resolve it (as of 1.04).
#
#  $orders->search([ 'Products/*/min','eq',100 ], 'and',
#                  [ 'Products/*/max','eq',250 ]);
# Will match, while:
#  $orders->search([ 'Products/1/min','eq',100 ], 'and',
#                  [ 'Products/1/max','eq',250 ]);
# Will not as it will try both on the same product. Default should be to
# treat as if /1/ was everywhere.
#
# am@xao.com, Sep/10, 2002
#
sub test_deep_variants {
    my $self=shift;
    my $odb=$self->get_odb();

    my %struct=(
        Orders => {
            type        => 'list',
            class       => 'Data::Order',
            key         => 'order_id',
            structure   => {
                Products => {
                    type        => 'list',
                    class       => 'Data::Product',
                    key         => 'order_id',
                    structure   => {
                        min => {
                            type        => 'integer',
                            minvalue    => 0,
                        },
                        max => {
                            type        => 'integer',
                            minvalue    => 0,
                        },
                    },
                },
                name => {
                    type        => 'text',
                    maxlength   => 200,
                },
            },
        },
    );

    $odb->fetch('/')->build_structure(\%struct);
    my $orders=$odb->fetch('/Orders');
    $self->deep_variants($orders);

    $odb->fetch('/')->drop_placeholder('Orders');
    my $c1=$odb->fetch('/Customers/c1');
    $c1->build_structure(\%struct);
    $self->deep_variants($c1->get('Orders'));
    my $c2=$odb->fetch('/Customers/c2');
    $self->deep_variants($c2->get('Orders'));
}

sub deep_variants {
    my $self=shift;
    my $orders=shift;

    my $on=$orders->get_new();
    $on->put(name => 'qwerty');
    $orders->put(o1 => $on);
    my $products=$orders->get('o1')->get('Products');
    my $pn=$products->get_new;
    $pn->put(min => 100);
    $pn->put(max => 200);
    $products->put(p1 => $pn);
    $pn->put(min => 150);
    $pn->put(max => 250);
    $products->put(p2 => $pn);
    $pn->put(min => 250);
    $pn->put(max => 350);
    $products->put(p3 => $pn);
    $pn->put(min => 350);
    $pn->put(max => 450);
    $products->put(p4 => $pn);
    $pn->put(min => 450);
    $pn->put(max => 550);
    $products->put(p5 => $pn);

    my $sr=$orders->search([ 'Products/*/min','eq',100 ], 'and',
                           [ 'Products/*/max','eq',250 ]);
    $self->assert(scalar(@$sr)==1 && $sr->[0] eq 'o1',
                  "Wrong /*/ deep search in test_deep_variants");

    $sr=$orders->search([ 'Products/1/min','eq',100 ], 'and',
                        [ 'Products/1/max','eq',250 ]);
    $self->assert(scalar(@$sr)==0,
                  "Wrong /1/ deep search in test_deep_variants");

    $sr=$orders->search([ 'Products/min','eq',100 ], 'and',
                        [ 'Products/max','eq',250 ]);
    $self->assert(scalar(@$sr)==0,
                  "Wrong default deep search in test_deep_variants");

    $sr=$orders->search([ 'Products/*/min','eq',100 ],
                        'and',
                        [ [ 'Products/*/max','gt',200 ],
                          'and',
                          [ [ 'Products/*/min','lt',300 ],
                            'and',
                            [ 'Products/*/max','eq',200 ],
                          ],
                        ]);
    $self->assert(scalar(@$sr)==1 && $sr->[0] eq 'o1',
                  "Wrong complex deep search in test_deep_variants");
}

###############################################################################
1;
