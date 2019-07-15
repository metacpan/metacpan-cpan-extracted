use 5.012;
use warnings;
use lib 't';
use MyTest;

# Class with wrapper

is(MyTest::MyBaseAV->new(0), undef, "create deny");
my $obj = new MyTest::MyBaseAV(777);
is(ref $obj, 'MyTest::MyBaseAV', "output OEXT_AV returns object");
$obj->[1] = 10;
is($obj->[1], 10, "OEXT_AV object is an ARRAYREF");
is($obj->val, 777, "input OEXT_AV works");
undef $obj;
cmp_deeply(dcnt(), [1,1], 'obj OEXT_AV desctructors called');

is(MyTest::MyBaseHV->new(0), undef, "create deny");
$obj = new MyTest::MyBaseHV(888);
is(ref $obj, 'MyTest::MyBaseHV', "output OEXT_HV returns object");
$obj->{abc} = 22;
is($obj->{abc}, 22, "OEXT_HV object is a HASHREF");
is($obj->val, 888, "input OEXT_HV works");
undef $obj;
cmp_deeply(dcnt(), [1,1], 'obj OEXT_HV desctructors called');

done_testing();
