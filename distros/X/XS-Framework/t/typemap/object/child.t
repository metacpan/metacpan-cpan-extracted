use 5.012;
use warnings;
use lib 't';
use MyTest;

my $test = sub {
    my ($class, $baseclass) = @{ shift() };
    dcnt();
    my $obj = $class->new(10, 20);
    is(ref $obj, $class, "output $class return object");
    is($obj->val, 10, "input THIS base method works");
    is($obj->val2, 20, "input THIS child method works");
    $obj->set_from($class->new(7,8));
    cmp_deeply(dcnt(), [2,2], 'tmp obj desctructors called');
    cmp_deeply([$obj->val, $obj->val2], [7,8], "input arg child method works");
    
    my $base = $baseclass->new(123);
    my $f = $class->can('val2');
    ok(!eval{$f->(); 1}, "input THIS doesnt allow wrong type objects");
    ok(!eval{$obj->set_from($base); 1}, "input arg doesnt allow wrong type objects");
    undef $base;
    undef $obj;
    cmp_deeply(dcnt(), [3,3], 'base and obj desctructors called');
};

subtest 'IV-ptr' => $test, ['MyTest::PTRMyChild', 'MyTest::PTRMyBase'];
subtest 'MG-ptr' => $test, ['MyTest::MyChild', 'MyTest::MyBase'];

done_testing();
