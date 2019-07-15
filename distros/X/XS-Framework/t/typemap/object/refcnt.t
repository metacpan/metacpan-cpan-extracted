use 5.012;
use warnings;
use lib 't';
use MyTest;

my $test = sub {
    dcnt();
    my ($class, $childclass, $hold_fname, $release_fname) = @{ shift() };
    my $hold = MyTest->can($hold_fname);
    my $release = MyTest->can($release_fname);
    
    my $o = $class->new(123);
    cmp_deeply(dcnt(), [0,0]);
    is(ref $o, $class, "class ok");
    dies_ok { $o->can("val")->(undef) } "undef not allowed";
    is($o->val, 123, "val ok");
    is($o->val, 123, "val ok");
    undef $o;
    cmp_deeply(dcnt(), [1,1], "dcnt ok");
    
    dcnt();
    $o = $childclass->new(123, 321);
    cmp_deeply(dcnt(), [0,0]);
    is(ref $o, $childclass);
    is($o->val, 123);
    is($o->val2, 321);
    undef $o;
    cmp_deeply(dcnt(), [2,2]);
    
    dcnt();
    $o = $class->new(890);
    $hold->($o);
    undef $o;
    cmp_deeply(dcnt(), [0,1]);
    my $o2 = $release->();
    cmp_deeply(dcnt(), [0,0]);
    is($o2->val, 890);
    undef $o2;
    cmp_deeply(dcnt(), [1,1]);
};

subtest 'IV-ptr'  => $test, ['MyTest::PTRMyRefCounted',     'MyTest::PTRMyRefCountedChild',     'hold_ptr_myrefcounted',      'release_ptr_myrefcounted'];
subtest 'MG-ptr'  => $test, ['MyTest::MyRefCounted',        'MyTest::MyRefCountedChild',        'hold_myrefcounted',          'release_myrefcounted'];
subtest 'IV-iptr' => $test, ['MyTest::PTRMyRefCountedIPTR', 'MyTest::PTRMyRefCountedChildIPTR', 'hold_ptr_myrefcounted_iptr', 'release_ptr_myrefcounted_iptr'];
subtest 'MG-iptr' => $test, ['MyTest::MyRefCountedIPTR',    'MyTest::MyRefCountedChildIPTR',    'hold_myrefcounted_iptr',     'release_myrefcounted_iptr'];
subtest 'IV-sp'   => $test, ['MyTest::PTRMyBaseSP',         'MyTest::PTRMyChildSP',             'hold_ptr_mybase_sp',         'release_ptr_mybase_sp'];
subtest 'MG-sp'   => $test, ['MyTest::MyBaseSP',            'MyTest::MyChildSP',                'hold_mybase_sp',             'release_mybase_sp'];

done_testing();
