use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder qw(:inline);

my $cache_dir = tempdir(CLEANUP => 1);

# Test inline type constants
is(INLINE_NONE, 0, 'INLINE_NONE is 0');
is(INLINE_GETTER, 1, 'INLINE_GETTER is 1');
is(INLINE_SETTER, 2, 'INLINE_SETTER is 2');
is(INLINE_HV_GETTER, 3, 'INLINE_HV_GETTER is 3');
is(INLINE_HV_SETTER, 4, 'INLINE_HV_SETTER is 4');

# Test op-based read-only accessor generation
{
    my $b = XS::JIT::Builder->new;
    
    $b->op_ro_accessor('get_name', 0);
    
    my $code = $b->code;
    like($code, qr/XS_EUPXS\(get_name\)/, 'op_ro_accessor generates XS function');
    like($code, qr/AvARRAY/, 'op_ro_accessor uses AvARRAY');
    like($code, qr/Read only attributes cannot be set/, 'op_ro_accessor has readonly check');
}

# Test op-based read-write accessor generation
{
    my $b = XS::JIT::Builder->new;
    
    $b->op_rw_accessor('name', 1);
    
    my $code = $b->code;
    like($code, qr/XS_EUPXS\(name\)/, 'op_rw_accessor generates XS function');
    like($code, qr/av_store/, 'op_rw_accessor uses av_store for setter');
    like($code, qr/AvARRAY/, 'op_rw_accessor uses AvARRAY for getter');
}

# Test compiling and using slot accessors
{
    package SlotTest;
    
    my $b = XS::JIT::Builder->new;
    
    $b->op_ro_accessor('slot0', 0);
    $b->op_rw_accessor('slot1', 1);
    $b->op_rw_accessor('slot2', 2);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'SlotTest',
        cache_dir => $cache_dir,
        functions => {
            'SlotTest::slot0' => { source => 'slot0', is_xs_native => 1 },
            'SlotTest::slot1' => { source => 'slot1', is_xs_native => 1 },
            'SlotTest::slot2' => { source => 'slot2', is_xs_native => 1 },
        },
    );
    
    sub new {
        my $class = shift;
        bless ['init0', 'init1', 'init2'], $class;
    }
}

my $obj = SlotTest->new;

# Test slot getters
is($obj->slot0, 'init0', 'slot0 getter works');
is($obj->slot1, 'init1', 'slot1 getter works');
is($obj->slot2, 'init2', 'slot2 getter works');

# Test slot setters
is($obj->slot1('new1'), 'new1', 'slot1 setter returns new value');
is($obj->slot1, 'new1', 'slot1 setter persists');

$obj->slot2('new2');
is($obj->slot2, 'new2', 'slot2 setter works');

# Test read-only enforcement
eval { $obj->slot0('fail') };
like($@, qr/Read only/, 'slot0 rejects setter call');

# Test inline_init
ok(eval { XS::JIT::Builder::inline_init(); 1 }, 'inline_init works');

# Test inline_register and inline_get_type
{
    package InlineTest;
    use XS::JIT::Builder qw(:inline);
    
    my $b = XS::JIT::Builder->new;
    $b->op_ro_accessor('iname', 0);
    $b->op_rw_accessor('iage', 1);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'InlineTest',
        cache_dir => $cache_dir,
        functions => {
            'InlineTest::iname' => { source => 'iname', is_xs_native => 1 },
            'InlineTest::iage'  => { source => 'iage',  is_xs_native => 1 },
        },
    );
    
    # Register inline ops
    my $cv_name = \&InlineTest::iname;
    my $cv_age  = \&InlineTest::iage;
    
    main::ok(XS::JIT::Builder::inline_register($cv_name, INLINE_GETTER, 0), 
       'inline_register for getter returns true');
    main::ok(XS::JIT::Builder::inline_register($cv_age, INLINE_SETTER, 1),
       'inline_register for setter returns true');
    
    main::is(XS::JIT::Builder::inline_get_type($cv_name), INLINE_GETTER,
       'inline_get_type returns INLINE_GETTER');
    main::is(XS::JIT::Builder::inline_get_type($cv_age), INLINE_SETTER,
       'inline_get_type returns INLINE_SETTER');
    
    sub new {
        my $class = shift;
        bless ['Alice', 30], $class;
    }
}

# Test that inline ops work correctly
{
    my $obj = InlineTest->new;
    
    # These should use the custom inline ops now
    is($obj->iname, 'Alice', 'inline getter works');
    is($obj->iage, 30, 'inline rw accessor getter works');
    
    $obj->iage(31);
    is($obj->iage, 31, 'inline rw accessor setter works');
}

done_testing;
