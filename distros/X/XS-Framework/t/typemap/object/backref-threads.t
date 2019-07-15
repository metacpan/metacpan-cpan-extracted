use 5.012;
use warnings;
use lib 't';
use MyTest 'threads';

use Devel::Peek;

my ($obj, $thr, $br_addr, $s);
my @thres : shared;
dcnt();

# 1) clone-policy, backref should point to cloned SV after clone
$obj = MyTest::MyBRUnit->new_enabled(100);
$br_addr = $obj->br_addr;

$thr = threads->create(sub {
    $obj->id(200);
    my $s = MyTest::BRStorage->new;
    $s->unit($obj);
    my $r = $s->unit;
    @thres = (ref($obj), $obj->id, $obj->br_addr, ref($r), $r->id, $r->br_addr);
    $s->unit(undef);
    undef $obj;
    undef $r;
});
$thr->join;
undef $thr;
is($obj->id, 211, "main thread object not damaged");
is($obj->br_addr, $br_addr, "main thread object not damaged");
cmp_deeply([@thres[0,1,3,4]], ["MyTest::MyBRUnit", 311, "MyTest::MyBRUnit", 311], "object works in thread");
is($thres[2], $thres[5], "XSBackref work in thread");
isnt($thres[2], $br_addr, "XSBackref has detached in thread");
cmp_deeply(dcnt(), [2, 2], "thread not leaked (storage and cloned unit have been destroyed)");

# check that after thread cloned, last reference from C correctly destroyed
$thr = threads->create(sub {
    $obj->id(200);
    my $s = MyTest::BRStorage->new;
    $s->unit($obj);
    my $r = $s->unit;
    undef $obj;
    undef $r;
    $s->unit(undef);
});
$thr->join;
undef $thr;
cmp_deeply(dcnt(), [2, 2], "thread not leaked (storage and cloned unit have been destroyed)");

# inside-C (deeply) cloned objects don't preserve backrefs (impossible)
$s = MyTest::BRStorage->new;
$s->unit($obj);
$thr = threads->create(sub {
    $obj->id(300);
    my $r = $s->unit;
    $r->id(400);
    @thres = (ref($obj), $obj->id, $obj->br_addr, ref($r), $r->id, $r->br_addr);
});
$thr->join;
undef $thr;
is($obj->id, 211);
is($obj->br_addr, $br_addr);
cmp_deeply([@thres[0,1,3,4]], ["MyTest::MyBRUnit", 411, "MyTest::BRUnit", 400]);
isnt($thres[2], $thres[5]);
isnt($thres[2], $br_addr);
isnt($thres[5], $br_addr);
cmp_deeply(dcnt(), [3, 3], "thread not leaked (obj + storage + storage's unit)");

# create thread when obj is in zombie mode
$s = MyTest::BRStorage->new;
$s->unit($obj);
undef $obj;
$thr = threads->create(sub {
    my $r = $s->unit;
});
$thr->join;
undef $thr;

done_testing();
