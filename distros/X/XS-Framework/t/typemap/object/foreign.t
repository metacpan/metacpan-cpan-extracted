use 5.012;
use warnings;
use lib 't';
use MyTest;

my $test = sub {
    my $class = shift;
    dcnt();
    
    my $obj = $class->get();
    is(ref $obj, $class, "output $class return object");
    is($obj->val, 789, "input THIS for $class works");
    $obj->val(123);
    is($obj->val, 123, "set for $class works");
    my $f = $class->can('val');
    ok(!eval {$f->(undef); 1}, "input THIS for $class doesnt allow undefs");
    
    undef $obj;
    cmp_deeply(dcnt(), [0,1], '$obj desctructor called, c++ class alive');
};

subtest 'MG-foreign' => $test, 'MyTest::MyForeign';

done_testing();
