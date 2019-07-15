use 5.012;
use warnings;
use lib 't';
use MyTest;

my $test = sub {
    dcnt();
    my ($class, $childclass) = @{ shift() };
    my $obj = $class->new(123);
    is(ref $obj, $class, "output returns object");
    is($obj->val, 123, "input works");
    my $f = $class->can('val');
    ok(!eval {$f->(undef); 1}, "input THIS doesnt allow undefs");
    undef $obj;
    
    $obj = $childclass->new(123, 321);
    is(ref $obj, $childclass, "output returns object");
    cmp_deeply([$obj->val, $obj->val2], [123, 321], "input works");
    my $f2 = $childclass->can('val2');
    ok(!eval {$f->(undef); 1}, "input THIS doesnt allow undefs");
    ok(!eval {$f2->(undef); 1}, "input THIS doesnt allow undefs");
    undef $obj;
};

subtest 'IV' => $test, ['MyTest::PTRMyStatic', 'MyTest::PTRMyStaticChild'];
subtest 'MG' => $test, ['MyTest::MyStatic',    'MyTest::MyStaticChild'];

done_testing();
