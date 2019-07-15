use 5.012;
use warnings;
use lib 't';
use MyTest;

use Devel::Peek;

dcnt();
my $s = MyTest::BRStorage->new();
is($s->unit(), undef, "storage is empty on creation");
    
subtest 'basic class' => sub {
    my $u = MyTest::BRUnit->new(100);
    is(ref $u, "MyTest::BRUnit", "correct class created");
    is($u->id, 100, "id ok");
    $s->unit($u);
    my $r = $s->unit;
    is(ref $r, "MyTest::BRUnit", "correct class got from storage");
    is($r->id, 100, "id ok");
    $s->unit(undef);
    is($s->unit(), undef, "storage cleared");
    undef $u;
    cmp_deeply(dcnt(), [0,1], "perl dtor, c alive");
    undef $r;
    cmp_deeply(dcnt(), [1,1], "perl dtor, c dtor");
};
dcnt();

subtest "subclassing with non-xsbackref class has no effect even with 'backref' param in typemap" => sub {
    my $u = MyTest::MyBRUnit->new(200);
    is(ref $u, "MyTest::MyBRUnit", "correct class created");
    is($u->id, 311, "id ok");
    $s->unit($u);
    my $r = $s->unit;
    is(ref $r, "MyTest::BRUnit", "correct class got from storage");
    is($r->id, 200, "id ok");
    undef $u;
    cmp_deeply(dcnt(), [0,1], "perl dtor, c alive");
    undef $r;
    cmp_deeply(dcnt(), [0,1], "perl dtor, c alive");
    $s->unit(undef);
    cmp_deeply(dcnt(), [1,0], "c dtor");
};
dcnt();
    
subtest 'subclassing with xsbackref class preserves original perl object' => sub {
    my $u = MyTest::MyBRUnit->new_enabled(200);
    is(ref $u, "MyTest::MyBRUnit", "correct class created");
    is($u->id, 311, "id ok");
    $s->unit($u);
    my $r = $s->unit;
    is($r, $u, "same object returned");
    is(ref $r, "MyTest::MyBRUnit", "correct class got from storage");
    is($r->id, 311, "id ok");
    undef $r;
    cmp_deeply(dcnt(), [0,0], "no dtors");
    undef $u;
    cmp_deeply(dcnt(), [0,0], "no dtors");
    is($s->unit->id, 311, "id ok");
    cmp_deeply(dcnt(), [0,0], "no dtors");
    $s->unit(undef);
    cmp_deeply(dcnt(), [1,1], "perl dtor, c dtor");
    
    $u = MyTest::MyBRUnit->new_enabled(300);
    $s->unit($u);
    $r = $s->unit;
    $s->unit(undef);
    cmp_deeply(dcnt(), [0,0], "no dtors");
    undef $r;
    cmp_deeply(dcnt(), [0,0], "no dtors");
    undef $u;
    cmp_deeply(dcnt(), [1,1], "perl dtor, c dtor");
};
    
subtest 'perl data can be used after PERL -> C -> PERL' => sub {
    dcnt();
    my $s = MyTest::BRStorage->new;
    my $u = MyTest::MyBRUnitAdvanced->new(200, 777);
    is(ref $u, "MyTest::MyBRUnitAdvanced", "correct class created");
    is($u->id, 311, "id ok");
    is($u->special, 777, "custom method");
    $s->unit($u);
    my $r = $s->unit;
    is(ref $r, "MyTest::MyBRUnitAdvanced", "correct class got from storage");
    is($r->id, 311, "id ok");
    is($r->special, 777, "custom method");
    undef $u; undef $r;
    cmp_deeply(dcnt(), [0,0], "no dtors");
    $s->unit(undef);
    cmp_deeply(dcnt(), [1,1], "perl dtor, c dtor");
};

subtest 'check that perl object survives if retained from C, even when perl loses all references (shared ref counter)' => sub {
    my $s = MyTest::BRStorage->new;
    dcnt();
    my $u = MyTest::MyBRUnitAdvanced->new(200, 777);
    $s->unit($u);
    undef $u;
    my $r = $s->unit;
    is(ref $r, "MyTest::MyBRUnitAdvanced", "correct class got from storage");
    is($r->id, 311, "id ok");
    is($r->special, 777, "custom method");
};

subtest 'global destruction' => sub {
    our @SAVE;
    
    #normal
    push @SAVE, MyTest::MyBRUnit->new_enabled(222);
    
    { #zombie deleted from c-dtor
        my $s = MyTest::BRStorage->new();
        push @SAVE, $s;
        $s->unit(MyTest::MyBRUnit->new_enabled(333));
    }
    
    { #zombie deleted by perl (when c class leaked or not yet destroyed)
        my $u = MyTest::MyBRUnit->new_enabled(666);
        $u->retain;
    }
    
    pass("results in destruction");
};

done_testing();