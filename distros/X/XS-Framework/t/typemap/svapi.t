use 5.012;
use warnings;
use lib 't';
use MyTest;

our @simple = (0, "", 100, "asdf");
our @sub    = (sub {});
our @oarr   = (bless [], 'main');
our @ohash  = (bless {}, 'main');
our @object = (@oarr, @ohash);
our @array  = ([], @oarr);
our @stash  = (\%main::);
our @hash   = ({}, @stash, @ohash);
our @ref    = (\100, \"asdf", @array, @hash, @sub, @stash);
our @glob   = (*simple);
our @all    = (@simple, @ref, @glob);

sub invert {
    grep { my $val = $_; scalar(grep { ($_//'') eq ($val//'') } @_) == 0 } @all;
}

subtest 'Sv' => sub {
    # OUTPUT
    is(MyTest::SvAPI::sv_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::sv_out($_), $_, "output normal $_") for @all;
    my $arr = [1,2,"asd"];
    cmp_deeply([MyTest::SvAPI::sv_out($arr, 1)], $arr, "output array");
    my $hash = {a => 1, b => "x"};
    cmp_deeply([MyTest::SvAPI::sv_out($hash, 1)], bag(%$hash), "output hash");
};

subtest 'Scalar' => sub {
    # OUTPUT
    is(MyTest::SvAPI::scalar_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::scalar_out($all[0]), $all[0], "output normal");
    # INPUT
    ok(MyTest::SvAPI::scalar_in(undef), "input undef as undef");
    ok(MyTest::SvAPI::scalar_in($_), "input correct value $_") for @all;
};

subtest 'Simple' => sub {
    # OUTPUT
    is(MyTest::SvAPI::simple_out(), undef, "output empty");
    is(MyTest::SvAPI::simple_out($simple[0]), $simple[0], "output normal");
    # INPUT
    ok(MyTest::SvAPI::simple_in(undef), "input undef as undef");
    ok(MyTest::SvAPI::simple_in($_), "input correct value $_") for @simple;
    ok(!eval { MyTest::SvAPI::simple_in($_); 1 }, "input incorrect value $_") for invert(@simple);
};

subtest 'Ref' => sub {
    # OUTPUT
    is(MyTest::SvAPI::ref_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::ref_out($ref[0]), $ref[0], "output normal");
    # INPUT
    is(MyTest::SvAPI::ref_in(undef), 0, "input undef as NULL");
    ok(MyTest::SvAPI::ref_in($_), "input correct value $_") for @ref;
    ok(!eval { MyTest::SvAPI::ref_in($_); 1 }, "input incorrect value $_") for invert(@ref);
};

subtest 'Glob' => sub {
    # OUTPUT
    is(MyTest::SvAPI::glob_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::glob_out($glob[0]), $glob[0], "output normal");
    # INPUT
    is(MyTest::SvAPI::glob_in(undef), 0, "input undef as NULL");
    ok(MyTest::SvAPI::glob_in($_), "input correct value $_") for @glob;
    ok(!eval { MyTest::SvAPI::glob_in($_); 1 }, "input incorrect value $_") for invert(@glob);
};

subtest 'Sub' => sub {
    # OUTPUT
    is(MyTest::SvAPI::sub_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::sub_out($sub[0]), $sub[0], "output normal");
    # INPUT
    is(MyTest::SvAPI::sub_in(undef), 0, "input undef as NULL");
    ok(MyTest::SvAPI::sub_in($_), "input correct value $_") for @sub;
    ok(!eval { MyTest::SvAPI::sub_in($_); 1 }, "input incorrect value $_") for invert(@sub);
};

subtest 'Array' => sub {
    # OUTPUT
    is(MyTest::SvAPI::array_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::array_out($array[0]), $array[0], "output normal");
    # INPUT
    is(MyTest::SvAPI::array_in(undef), 0, "input undef as NULL");
    ok(MyTest::SvAPI::array_in($_), "input correct value $_") for @array;
    ok(!eval { MyTest::SvAPI::array_in($_); 1 }, "input incorrect value $_") for invert(@array);
};

subtest 'Hash' => sub {
    # OUTPUT
    is(MyTest::SvAPI::hash_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::hash_out($hash[0]), $hash[0], "output normal");
    # INPUT
    is(MyTest::SvAPI::hash_in(undef), 0, "input undef as NULL");
    ok(MyTest::SvAPI::hash_in($_), "input correct value $_") for @hash;
    ok(!eval { MyTest::SvAPI::hash_in($_); 1 }, "input incorrect value $_") for invert(@hash);
};

subtest 'Stash' => sub {
    # OUTPUT
    is(MyTest::SvAPI::stash_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::stash_out($stash[0]), $stash[0], "output normal");
    # INPUT
    is(MyTest::SvAPI::stash_in(undef), 0, "input undef as NULL");
    ok(MyTest::SvAPI::stash_in($_), "input correct value $_") for @stash;
    ok(!eval { MyTest::SvAPI::stash_in($_); 1 }, "input incorrect value $_") for invert(@stash);
};

subtest 'Object' => sub {
    # OUTPUT
    is(MyTest::SvAPI::object_out(), undef, "output empty");
    cmp_deeply(MyTest::SvAPI::object_out($object[0]), $object[0], "output normal");
    # INPUT
    is(MyTest::SvAPI::object_in(undef), 0, "input undef as NULL");
    ok(MyTest::SvAPI::object_in($_), "input correct value $_") for @object;
    ok(!eval { MyTest::SvAPI::object_in($_); 1 }, "input incorrect value $_") for invert(@object);
};

done_testing();
