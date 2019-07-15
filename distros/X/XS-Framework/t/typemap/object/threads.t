use 5.012;
use warnings;
use lib 't';
use MyTest 'threads';

my ($obj, $thr);
my @thres : shared;

# 1) object has CLONE_SKIP (not support threads)
$obj = MyTest::MixBase->new(123);
is($obj->val, 123);
$thr = threads->create(\&thr_mybase);
$thr->join;
is($obj->val, 123);
cmp_deeply(\@thres, ['SCALAR', undef, undef], "XS MixBase must self-destroy");
cmp_deeply(dcnt(), [0,0], 'MixBase must not exist in thread');
undef $obj;
cmp_deeply(dcnt(), [1,1], 'MixBase has been destroyed in parent');

# 2) object is thread-unsafe, clones itself on thread creation
$obj = MyTest::MyChild->new(234, 345);
cmp_deeply([$obj->val, $obj->val2], [234, 345]);
@thres = ();
$thr = threads->create(\&thr_mychild);
$thr->join;
cmp_deeply([$obj->val, $obj->val2], [234, 345], 'Parent thread MyChild object not changed');
cmp_deeply(\@thres, ['MyTest::MyChild', 100, 200], 'Child thread MyChild object works and changed');
cmp_deeply(dcnt(), [2,2], 'MyChild has been destroyed in thread');
undef $obj;
cmp_deeply(dcnt(), [2,2], 'MyChild has been destroyed in parent also');

# 3) object is thread-safe, increments refcnt on thread creation
$obj = MyTest::MyThreadSafe->new(12);
is($obj->val, 12);
@thres = ();
$thr = threads->create(\&thr_mythread_safe);
$thr->join;
is($obj->val, 100, 'Parent thread MyThreadSafe object changed');
cmp_deeply(\@thres, ['MyTest::MyThreadSafe', 100], 'Child thread MyChild object works and same');
cmp_deeply(dcnt(), [0,1], 'MyThreadSafe has not been destroyed in thread, but perl object-wrapper has');
undef $obj;
cmp_deeply(dcnt(), [1,1], 'MyThreadSafe has been destroyed in parent');

done_testing();

sub thr_mybase {
    @thres = (ref($obj), $$obj, scalar eval { $obj->val; 1 });
}

sub thr_mychild {
    $obj->val(100);
    $obj->val2(200);
    @thres = (ref($obj), $obj->val, $obj->val2);
}

sub thr_mythread_safe {
    $obj->val(100);
    @thres = (ref($obj), $obj->val);
}