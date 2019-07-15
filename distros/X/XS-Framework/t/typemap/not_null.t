use 5.012;
use warnings;
use lib 't';
use MyTest;

my $obj = MyTest::NotNull->new(10);
my $obj2 = MyTest::NotNull->new(20);

subtest 'pointer' => sub {
    $obj->set_from($obj2);
    is $obj->val, 20, "not-null arg ok";
    dies_ok { $obj->set_from(undef) } "null arg dies";
};

subtest 'iptr' => sub {
    $obj2 = MyTest::NotNull->new(30);
    $obj->set_from2($obj2);
    is $obj->val, 30, "not-null arg ok";
    dies_ok { $obj->set_from2(undef) } "null arg dies";
};


done_testing();
