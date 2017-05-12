#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use List::Util qw( shuffle );
use Data::Dumper;

use Tie::TimeSeries;

plan tests => 6;

my ( $tied, %hash, $order );

# subtest 1 ----------
subtest 'Tying with arguments subtest' => sub {
    plan tests => 8;

    # 1
    $tied  = tie %hash, 'Tie::TimeSeries', 0=>0, 1=>10, 2=>20, 3=>30;
    $order = join(",", (keys %hash) );
    ok( $order eq '0,1,2,3', "Keys order ck 1 ... ($order)");

    # 2
    $order = join(",", (values %hash) );
    ok( $order eq '0,10,20,30', "Values order ck 1 ... ($order)");

    # 3
    $tied  = tie %hash, 'Tie::TimeSeries', 1=>10, 3=>30, 2=>20, 0=>0;
    $order = join(",", (keys %hash) );
    ok( $order eq '0,1,2,3', "Keys order ck 2 ... ($order)");

    # 4
    $order = join(",", (values %hash) );
    ok( $order eq '0,10,20,30', "Values order ck 2 ... ($order)");

    # 5 - large data
    my $num = 4096;
    my @args = map { ($_ => $_*10) } (0..$num);
    $tied  = tie %hash, 'Tie::TimeSeries', @args;
    $order = join(",", (keys %hash) );
    ok( $order eq join(",",(0..$num)), "Values order ck 3 ... ($order)");

    # 6 - large data
    $order = join(",", (values %hash) );
    ok( $order eq join(",",map { $_*10 } (0..$num)), "Values order ck 3 ... ($order)");

    # 7 - large data with random order (will use binary search logic)
    my %args = map { ($_ => $_*10) } shuffle (0..$num);
    $tied  = tie %hash, 'Tie::TimeSeries', %args;
    $order = join(",", (keys %hash) );
    ok( $order eq join(",",(0..$num)), "Values order ck 3 ... ($order)");

    # 8 - large data with random order (will use binary search logic)
    $order = join(",", (values %hash) );
    ok( $order eq join(",",map { $_*10 } (0..$num)), "Values order ck 3 ... ($order)");

};


# subtest 2 ----------
subtest 'Fetching subtest' => sub {
    plan tests => 10;

    $tied  = tie %hash, 'Tie::TimeSeries', 10=>10, 20=>20, 30=>30, 40=>40, 50=>50;

    # 1
    ok( $hash{10} == 10 , "Fetching test 1");

    # 2
    ok( $hash{30} == 30 , "Fetching test 2");

    # 3
    ok( $hash{50} == 50 , "Fetching test 3");

    # 4
    ok( !defined($hash{0}), "Fetching test 4");

    # 5
    ok( !defined($hash{5}), "Fetching test 5");

    # 6
    ok( !defined($hash{60}), "Fetching test 6");

    # 7
    $hash{0} = 0;
    ok( $hash{0} == 0, "Fetching test 7");

    # 8
    $hash{5} = 5;
    ok( $hash{5} == 5, "Fetching test 8");

    # 9
    $hash{60} = 60;
    ok( $hash{60} == 60, "Fetching test 9");

    # 10
    my $v;
    eval { $v=$hash{a} };
    ok( !defined($v), "Fetching test 10");
};


# subtest 3 ----------
subtest 'Inserting subtest' => sub {
    plan tests => 7;

    # 1
    $tied  = tie %hash, 'Tie::TimeSeries', 10=>10, 20=>20, 30=>30, 40=>40;
    $hash{15} = 15;
    $order = join(",", (keys %hash) );
    ok( $order eq '10,15,20,30,40', "Keys after insert ck 1 ... ($order)");

    # 2
    $order = join(",", (values %hash) );
    ok( $order eq '10,15,20,30,40', "Values after insert ck 1 ... ($order)");

    # 3
    $hash{5} = 5;
    $order = join(",", (keys %hash) );
    ok( $order eq '5,10,15,20,30,40', "Keys after insert ck 2 ... ($order)");

    # 4
    $order = join(",", (values %hash) );
    ok( $order eq '5,10,15,20,30,40', "Values after insert ck 2 ... ($order)");

    # 5
    $hash{45} = 45;
    $order = join(",", (keys %hash) );
    ok( $order eq '5,10,15,20,30,40,45', "Keys after insert ck 3 ... ($order)");

    # 6
    $order = join(",", (values %hash) );
    ok( $order eq '5,10,15,20,30,40,45', "Values after insert ck 3 ... ($order)");

    # 7 - bad key value
    eval { $hash{hanage} = 100; };
    $order = join(",", (values %hash) );
    ok( $order eq '5,10,15,20,30,40,45', "Values after bad key's insert ck ... ($order)");

};


# subtest 4 ----------
subtest 'Deleting subtest' => sub {
    plan tests => 8;

    # 1
    $tied  = tie %hash, 'Tie::TimeSeries', 10=>10, 20=>20, 30=>30, 40=>40, 50=>50;
    delete $hash{30};
    $order = join(",", (keys %hash) );
    ok( $order eq '10,20,40,50', "Keys after delete ck 1 ... ($order)");

    # 2
    $order = join(",", (values %hash) );
    ok( $order eq '10,20,40,50', "Values after delete ck 1 ... ($order)");

    # 3
    delete $hash{10};
    $order = join(",", (keys %hash) );
    ok( $order eq '20,40,50', "Keys after delete ck 2 ... ($order)");

    # 4
    $order = join(",", (values %hash) );
    ok( $order eq '20,40,50', "Values after delete ck 2 ... ($order)");

    # 5
    delete $hash{50};
    $order = join(",", (keys %hash) );
    ok( $order eq '20,40', "Keys after delete ck 3 ... ($order)");

    # 6
    $order = join(",", (values %hash) );
    ok( $order eq '20,40', "Values after delete ck 3 ... ($order)");

    # 7 - bad key value
    $@='';
    eval { delete $hash{hanage}; };
    $order = join(",", (values %hash) );
    ok( !$@ && $order eq '20,40', "Values after bad key's delete ck ... ($order)");

    # 8 - unexists key value
    delete $hash{100};
    $order = join(",", (values %hash) );
    ok( !$@ && $order eq '20,40', "Values after unexisting key's delete ck ... ($order)");
};


# subtest 5 ----------
subtest 'Calling exists() subtest' => sub {
    plan tests => 2;

    # 1
    $tied  = tie %hash, 'Tie::TimeSeries', 10=>10, 20=>20, 30=>30, 40=>40, 50=>50;
    ok( exists $hash{10}, "exists() ck 1");

    # 2
    ok( !exists $hash{100}, "exists() ck 2");
};


# subtest 6 ----------
subtest 'Calling each()' => sub {
    plan tests => 2;

    # 1
    $tied  = tie %hash, 'Tie::TimeSeries', 10=>10, 20=>20, 30=>30, 40=>40, 50=>50;
    my @k_order = ();
    my @v_order = ();
    while ( my ( $k, $v ) = each %hash ){
        push @k_order, $k;
        push @v_order, $v;
    }
    ok( join(',',@k_order) eq '10,20,30,40,50', "each() ck 1");

    # 2
    ok( join(',',@v_order) eq '10,20,30,40,50', "each() ck 2");
};


# ----------
#diag( "Testing Tie::TimeSeries $Tie::TimeSeries::VERSION, Perl $], $^X" );


