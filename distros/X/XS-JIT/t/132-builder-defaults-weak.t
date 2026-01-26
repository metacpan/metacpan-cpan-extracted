#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Scalar::Util qw(isweak);

use XS::JIT;
use XS::JIT::Builder qw(:types);

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================================================
# Test new_complete
# ============================================================================

subtest 'new_complete - required attr provided' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c1', [
        { name => 'id', required => 1 },
    ], 0);
    $b->rw_accessor('C1_id', 'id', 2);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete1',
        cache_dir => $cache_dir,
        functions => {
            'Complete1::new' => { source => 'new_c1', is_xs_native => 1 },
            'Complete1::id'  => { source => 'C1_id', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete1->new(id => 42);
    is($obj->id, 42, 'required attr set');
};

subtest 'new_complete - required attr missing' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c2', [
        { name => 'must_have', required => 1 },
    ], 0);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete2',
        cache_dir => $cache_dir,
        functions => {
            'Complete2::new' => { source => 'new_c2', is_xs_native => 1 },
        },
    );
    
    eval { Complete2->new() };
    like($@, qr/required.*must_have/i, 'croaks on missing required');
};

subtest 'new_complete - default_iv applied' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c3', [
        { name => 'count', default_iv => 100 },
    ], 0);
    $b->rw_accessor('C3_count', 'count', 5);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete3',
        cache_dir => $cache_dir,
        functions => {
            'Complete3::new'   => { source => 'new_c3', is_xs_native => 1 },
            'Complete3::count' => { source => 'C3_count', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete3->new();
    is($obj->count, 100, 'default_iv applied');
};

subtest 'new_complete - default_av creates empty arrayref' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c4', [
        { name => 'items', default_av => 1 },
    ], 0);
    $b->rw_accessor('C4_items', 'items', 5);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete4',
        cache_dir => $cache_dir,
        functions => {
            'Complete4::new'   => { source => 'new_c4', is_xs_native => 1 },
            'Complete4::items' => { source => 'C4_items', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete4->new();
    is_deeply($obj->items, [], 'default_av creates empty array');
    push @{$obj->items}, 'test';
    is_deeply($obj->items, ['test'], 'array is mutable');
};

subtest 'new_complete - default_hv creates empty hashref' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c5', [
        { name => 'meta', default_hv => 1 },
    ], 0);
    $b->rw_accessor('C5_meta', 'meta', 4);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete5',
        cache_dir => $cache_dir,
        functions => {
            'Complete5::new'  => { source => 'new_c5', is_xs_native => 1 },
            'Complete5::meta' => { source => 'C5_meta', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete5->new();
    is_deeply($obj->meta, {}, 'default_hv creates empty hash');
};

subtest 'new_complete - default_pv applies string' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c6', [
        { name => 'label', default_pv => 'default_label' },
    ], 0);
    $b->rw_accessor('C6_label', 'label', 5);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete6',
        cache_dir => $cache_dir,
        functions => {
            'Complete6::new'   => { source => 'new_c6', is_xs_native => 1 },
            'Complete6::label' => { source => 'C6_label', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete6->new();
    is($obj->label, 'default_label', 'default_pv applied');
};

subtest 'new_complete - provided value overrides default' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c7', [
        { name => 'value', default_iv => 999 },
    ], 0);
    $b->rw_accessor('C7_value', 'value', 5);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete7',
        cache_dir => $cache_dir,
        functions => {
            'Complete7::new'   => { source => 'new_c7', is_xs_native => 1 },
            'Complete7::value' => { source => 'C7_value', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete7->new(value => 42);
    is($obj->value, 42, 'provided value overrides default');
};

subtest 'new_complete - type validation passes' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c8', [
        { name => 'num', type => TYPE_INT, type_msg => 'num must be int' },
    ], 0);
    $b->rw_accessor('C8_num', 'num', 3);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete8',
        cache_dir => $cache_dir,
        functions => {
            'Complete8::new' => { source => 'new_c8', is_xs_native => 1 },
            'Complete8::num' => { source => 'C8_num', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete8->new(num => 42);
    is($obj->num, 42, 'valid int accepted');
};

subtest 'new_complete - type validation fails' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c9', [
        { name => 'num', type => TYPE_INT, type_msg => 'num must be int' },
    ], 0);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete9',
        cache_dir => $cache_dir,
        functions => {
            'Complete9::new' => { source => 'new_c9', is_xs_native => 1 },
        },
    );
    
    eval { Complete9->new(num => 'hello') };
    like($@, qr/num must be int/, 'type validation fails');
};

subtest 'new_complete - weak ref is weakened' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c10', [
        { name => 'parent', weak => 1 },
    ], 0);
    $b->rw_accessor('C10_parent', 'parent', 6);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete10',
        cache_dir => $cache_dir,
        functions => {
            'Complete10::new'    => { source => 'new_c10', is_xs_native => 1 },
            'Complete10::parent' => { source => 'C10_parent', is_xs_native => 1 },
        },
    );
    
    my $parent = bless {}, 'Parent';
    my $obj = Complete10->new(parent => $parent);
    ok(isweak($obj->{parent}), 'parent is weak reference');
};

subtest 'new_complete - coerce method called' => sub {
    # Create a class with a coercion method
    {
        package Complete11;
        sub to_int { 
            my ($class, $val) = @_;
            return int($val);
        }
    }
    
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c11', [
        { name => 'age', coerce => 'to_int' },
    ], 0);
    $b->rw_accessor('C11_age', 'age', 3);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete11',
        cache_dir => $cache_dir,
        functions => {
            'Complete11::new' => { source => 'new_c11', is_xs_native => 1 },
            'Complete11::age' => { source => 'C11_age', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete11->new(age => '42.7');
    is($obj->age, 42, 'coercion called');
};

subtest 'new_complete - call_build calls BUILD' => sub {
    {
        package Complete12;
        our $build_called = 0;
        sub BUILD { $build_called++ }
    }
    
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c12', [], 1);  # call_build = 1
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete12',
        cache_dir => $cache_dir,
        functions => {
            'Complete12::new' => { source => 'new_c12', is_xs_native => 1 },
        },
    );
    
    $Complete12::build_called = 0;
    my $obj = Complete12->new();
    is($Complete12::build_called, 1, 'BUILD was called');
};

subtest 'new_complete - multiple attrs work together' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c13', [
        { name => 'id', required => 1, type => TYPE_INT, type_msg => 'id must be int' },
        { name => 'name', default_pv => 'anon' },
        { name => 'items', default_av => 1 },
        { name => 'count', default_iv => 0 },
    ], 0);
    $b->rw_accessor('C13_id', 'id', 2);
    $b->rw_accessor('C13_name', 'name', 4);
    $b->rw_accessor('C13_items', 'items', 5);
    $b->rw_accessor('C13_count', 'count', 5);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete13',
        cache_dir => $cache_dir,
        functions => {
            'Complete13::new'   => { source => 'new_c13', is_xs_native => 1 },
            'Complete13::id'    => { source => 'C13_id', is_xs_native => 1 },
            'Complete13::name'  => { source => 'C13_name', is_xs_native => 1 },
            'Complete13::items' => { source => 'C13_items', is_xs_native => 1 },
            'Complete13::count' => { source => 'C13_count', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete13->new(id => 1);
    is($obj->id, 1, 'required id set');
    is($obj->name, 'anon', 'default name applied');
    is_deeply($obj->items, [], 'default items applied');
    is($obj->count, 0, 'default count applied');
};

subtest 'new_complete - hashref args work' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_complete('new_c14', [
        { name => 'x' },
        { name => 'y' },
    ], 0);
    $b->rw_accessor('C14_x', 'x', 1);
    $b->rw_accessor('C14_y', 'y', 1);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Complete14',
        cache_dir => $cache_dir,
        functions => {
            'Complete14::new' => { source => 'new_c14', is_xs_native => 1 },
            'Complete14::x'   => { source => 'C14_x', is_xs_native => 1 },
            'Complete14::y'   => { source => 'C14_y', is_xs_native => 1 },
        },
    );
    
    my $obj = Complete14->new({ x => 10, y => 20 });
    is($obj->x, 10, 'x from hashref');
    is($obj->y, 20, 'y from hashref');
};

# ============================================================================
# Test rw_accessor_weak
# ============================================================================

subtest 'rw_accessor_weak - stores reference' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_w1');
    $b->rw_accessor_weak('W1_parent', 'parent', 6);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Weak1',
        cache_dir => $cache_dir,
        functions => {
            'Weak1::new'    => { source => 'new_w1', is_xs_native => 1 },
            'Weak1::parent' => { source => 'W1_parent', is_xs_native => 1 },
        },
    );
    
    my $parent = bless {}, 'Parent';
    my $obj = Weak1->new();
    $obj->parent($parent);
    is(ref($obj->parent), 'Parent', 'stores reference');
};

subtest 'rw_accessor_weak - reference is weakened' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_w2');
    $b->rw_accessor_weak('W2_parent', 'parent', 6);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Weak2',
        cache_dir => $cache_dir,
        functions => {
            'Weak2::new'    => { source => 'new_w2', is_xs_native => 1 },
            'Weak2::parent' => { source => 'W2_parent', is_xs_native => 1 },
        },
    );
    
    my $parent = bless {}, 'Parent';
    my $obj = Weak2->new();
    $obj->parent($parent);
    ok(isweak($obj->{parent}), 'reference is weak');
};

subtest 'rw_accessor_weak - getter returns value' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_w3');
    $b->rw_accessor_weak('W3_parent', 'parent', 6);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Weak3',
        cache_dir => $cache_dir,
        functions => {
            'Weak3::new'    => { source => 'new_w3', is_xs_native => 1 },
            'Weak3::parent' => { source => 'W3_parent', is_xs_native => 1 },
        },
    );
    
    my $parent = bless { name => 'test' }, 'Parent';
    my $obj = Weak3->new();
    $obj->parent($parent);
    is($obj->parent->{name}, 'test', 'getter returns correct value');
};

subtest 'rw_accessor_weak - undef clears weak ref' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_w4');
    $b->rw_accessor_weak('W4_parent', 'parent', 6);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Weak4',
        cache_dir => $cache_dir,
        functions => {
            'Weak4::new'    => { source => 'new_w4', is_xs_native => 1 },
            'Weak4::parent' => { source => 'W4_parent', is_xs_native => 1 },
        },
    );
    
    my $parent = bless {}, 'Parent';
    my $obj = Weak4->new();
    $obj->parent($parent);
    ok(defined $obj->parent, 'parent is set');
    $obj->parent(undef);
    ok(!defined $obj->parent, 'parent is cleared');
};

# ============================================================================
# Test hv_store_weak (low-level)
# ============================================================================

subtest 'hv_store_weak - basic weak store' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('store_weak_test')
      ->xs_preamble
      ->get_self_hv
      ->if('items > 1')
        ->hv_store_weak('hv', 'ref', 3, 'newSVsv(ST(1))')
      ->endif
      ->xs_return_undef
      ->xs_end;
    
    $b->rw_accessor('SW_ref', 'ref', 3);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'StoreWeak',
        cache_dir => $cache_dir,
        functions => {
            'StoreWeak::store' => { source => 'store_weak_test', is_xs_native => 1 },
            'StoreWeak::ref'   => { source => 'SW_ref', is_xs_native => 1 },
        },
    );
    
    my $target = bless {}, 'Target';
    my $obj = bless {}, 'StoreWeak';
    $obj->store($target);
    ok(isweak($obj->{ref}), 'stored reference is weak');
};

subtest 'hv_store_weak - non-ref values unchanged' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('store_weak_test2')
      ->xs_preamble
      ->get_self_hv
      ->if('items > 1')
        ->hv_store_weak('hv', 'val', 3, 'newSVsv(ST(1))')
      ->endif
      ->xs_return_undef
      ->xs_end;
    
    $b->rw_accessor('SW2_val', 'val', 3);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'StoreWeak2',
        cache_dir => $cache_dir,
        functions => {
            'StoreWeak2::store' => { source => 'store_weak_test2', is_xs_native => 1 },
            'StoreWeak2::val'   => { source => 'SW2_val', is_xs_native => 1 },
        },
    );
    
    my $obj = bless {}, 'StoreWeak2';
    $obj->store(42);
    is($obj->val, 42, 'non-ref stored normally');
    ok(!isweak($obj->{val}), 'non-ref is not weak');
};

done_testing();
