use 5.012;
use lib 't';
use MyTest;

our %v;

subtest 'set CT' => sub {
    BEGIN {
        MyTest::Hints::set("epta", 123);
        $v{set} = $^H{epta};
    }
    is $v{set}, 123;
    ok MyTest::Hints::exists("epta");
    BEGIN { delete $^H{epta}; }
};

subtest 'exists RT' => sub {
    ok !MyTest::Hints::exists("epta");
    BEGIN { $^H{epta} = 1 }
    ok MyTest::Hints::exists("epta");
    BEGIN { delete $^H{epta} }
    ok !MyTest::Hints::exists("epta");
};

subtest 'get RT' => sub {
    is MyTest::Hints::get("epta"), undef;
    BEGIN { $^H{epta} = 123 }
    is MyTest::Hints::get("epta"), 123;
    BEGIN { delete $^H{epta} }
    is MyTest::Hints::get("epta"), undef;
};

subtest 'remove CT' => sub {
    BEGIN { $^H{epta} = 123 }
    is MyTest::Hints::get("epta"), 123;
    BEGIN { MyTest::Hints::remove("epta") }
    is MyTest::Hints::get("epta"), undef;
    ok !MyTest::Hints::exists("epta");
};

subtest 'get hash RT' => sub {
    is_deeply MyTest::Hints::get_hash(), {};
    BEGIN {
        MyTest::Hints::set("epta", 1);
        MyTest::Hints::set("epta2", "nah");
        MyTest::Hints::set("epta3", undef);
    }
    is_deeply MyTest::Hints::get_hash(), {epta => 1, epta2 => "nah", epta3 => undef};
    BEGIN {
        MyTest::Hints::remove("epta");
        MyTest::Hints::remove("epta2");
        MyTest::Hints::remove("epta3");
    }
    is_deeply MyTest::Hints::get_hash(), {};
};

subtest 'get CT' => sub {
    BEGIN {
        $^H{epta} = 123;
        $v{getct1} = MyTest::Hints::get("epta");
        $v{getct2} = MyTest::Hints::get_ct("epta");
    }
    is $v{getct1}, undef;
    is $v{getct2}, 123;
    is MyTest::Hints::get("epta"), 123;
};

done_testing();
