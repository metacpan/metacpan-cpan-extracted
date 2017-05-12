#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use List::Util qw( shuffle );
use Data::Dumper;

use Tie::TimeSeries;

plan tests => 5;

my ( $obj, $keys, $values, $order );

# subtest 1 ----------
subtest 'Making object subtest' => sub {
    plan tests => 7;

    # 1
    $obj   = Tie::TimeSeries->new();
    ok( ref($obj) eq 'Tie::TimeSeries', "Making object 1");

    # 2
    $keys = join(",", $obj->keys());
    ok( $keys eq '', "Making object 1");

    # 3
    $values = join(",", $obj->values());
    ok( $values eq '', "Making object 2");

    # 4
    $obj = Tie::TimeSeries->new(
        100 => 10,
        200 => 20,
        300 => 30,
        400 => 40,
        500 => 50,
    );
    $keys = join(",", $obj->keys());
    ok( $keys eq '100,200,300,400,500', "Making object and keys 1 ... ($keys)");

    # 5
    $values = join(",", $obj->values());
    ok( $values eq '10,20,30,40,50', "Making object and values 1 ... ($values)");

    # 6
    $obj = Tie::TimeSeries->new(
        100 => 10,
        200 => 20,
        'a' => 'b',
        300 => 30,
        400 => 40,
        500 => 50,
    );
    $keys = join(",", $obj->keys());
    ok( $keys eq '100,200,300,400,500', "Making object and keys 2 ... ($keys)");

    # 7
    $values = join(",", $obj->values());
    ok( $values eq '10,20,30,40,50', "Making object and values 2 ... ($values)");

};


# subtest 2 ----------
subtest 'Fetching and storing subtest' => sub {
    plan tests => 17;

    $obj = Tie::TimeSeries->new(
        100 => 10,
        200 => 20,
        300 => 30,
        400 => 40,
        500 => 50,
    );

    # 1
    ok( $obj->fetch(100) == 10 , "Fetching test 1");

    # 2
    ok( $obj->fetch(300) == 30 , "Fetching test 2");

    # 3
    ok( $obj->fetch(500) == 50 , "Fetching test 3");

    # 4
    ok( !defined($obj->fetch(0)), "Fetching test 4");

    # 5
    ok( !defined($obj->fetch(5)), "Fetching test 5");

    # 6
    ok( !defined($obj->fetch(60)), "Fetching test 6");

    # 7
    $obj->store(0=>0);
    ok( $obj->fetch(0) == 0 , "Storing test 1");

    # 8
    $obj->store(0=>1, 50=>2, 600=>3);
    ok( $obj->fetch(0) == 1 , "Storing test(with arrah) 2");

    # 9
    ok( $obj->fetch(50) == 2 , "Storing test(with arrah) 3");

    # 10
    ok( $obj->fetch(600) == 3 , "Storing test(with arrah) 4");

    # 11
    $obj->store({0=>2, 50=>5, 600=>60});
    ok( $obj->fetch(0) == 2 , "Storing test(with hashref) 5");

    # 12
    $obj->store({0=>2, 50=>5, 600=>60});
    ok( $obj->fetch(50) == 5 , "Storing test(with hashref) 6");

    # 13
    $obj->store({0=>2, 50=>5, 600=>60});
    ok( $obj->fetch(600) == 60 , "Storing test(with hashref) 7");

    # 14
    my $ret = join(',', $obj->fetch(0));
    ok( $ret == 2, "Fetching test 2-1");

    # 15
    $ret = join(',', $obj->fetch(0,600,300));
    ok( $ret eq '2,60,30', "Fetching test(with array) 2-2 ($ret)");

    # 16
    $ret = join(',', $obj->fetch([0,600,300]));
    ok( $ret eq '2,60,30', "Fetching test(with arrayref) 2-3 ($ret)");

    # 17
    $ret = $obj->fetch(900);
    ok( !defined($ret), "Fetching test(undef value) 2-4");
};


# subtest 3 ----------
subtest 'Deleting subtest' => sub {
    plan tests => 4;

    $obj = Tie::TimeSeries->new(
        100 => 10,
        200 => 20,
        300 => 30,
        400 => 40,
        500 => 50,
    );

    # 1
    my $ret = $obj->delete(10);
    ok( !defined($ret), "delete test, unstored value");

    # 2
    $ret = $obj->delete(100);
    $values = join(",", $obj->values());
    ok( $ret == 10 && $values eq '20,30,40,50', "delete test 2");

    # 3
    my @ret = $obj->delete(200,300);
    $values = join(",", $obj->values());
    ok( join(',',@ret) eq '20,30' && $values eq '40,50', "delete test 3");

    # 4
    @ret = $obj->delete([400,500]);
    $values = join(",", $obj->values());
    ok( join(',',@ret) eq '40,50' && $values eq '', "delete test 4");
};


# subtest 4 ----------
subtest 'Calling exists() subtest' => sub {
    plan tests => 3;

    $obj = Tie::TimeSeries->new(
        100 => 10,
        200 => 20,
        300 => 30,
        400 => 40,
        500 => 50,
    );

    # 1
    ok( !defined($obj->exists(0)), "exists() ck 1");

    # 2
    ok( $obj->exists(100), "exists() ck 2");

    # 2
    ok( !defined($obj->exists(600)), "exists() ck 3");
};


# subtest 5 ----------
subtest 'Calling iterate()' => sub {
    plan tests => 2;

    $obj = Tie::TimeSeries->new(
        100 => 10,
        200 => 20,
        300 => 30,
        400 => 40,
        500 => 50,
    );
    my @k_order = ();
    my @v_order = ();

    # 1
    $obj->iterate( sub {
        my ( $k, $v ) = @_;
        push @k_order, $k;
        push @v_order, $v;
    } );
    ok( join(',',@k_order) eq '100,200,300,400,500', "iterate() ck 1");

    # 2
    ok( join(',',@v_order) eq '10,20,30,40,50', "iterate() ck 2");
};




# ----------
#diag( "Testing Tie::TimeSeries $Tie::TimeSeries::VERSION, Perl $], $^X" );


