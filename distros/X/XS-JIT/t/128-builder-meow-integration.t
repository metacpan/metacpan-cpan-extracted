#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::Temp qw(tempdir);
use XS::JIT;
use XS::JIT::Builder;

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test lazy_init_dor - actually compile and run
# ============================================
subtest 'lazy_init_dor runtime' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Create a lazy init accessor for 'items' that defaults to []
    $b->lazy_init_dor('LazyTest_items', 'items', 5, 'newRV_noinc((SV*)newAV())', 0);
    
    my $code = $b->code;
    
    eval {
        XS::JIT->compile(
            code      => $code,
            name      => 'LazyTest',
            cache_dir => $cache_dir,
            functions => {
                'LazyTest::items' => { source => 'LazyTest_items', is_xs_native => 1 },
            },
        );
    };
    ok(!$@, 'Compile succeeded') or diag $@;
    
    my $obj = bless {}, 'LazyTest';
    
    # First call - should create default arrayref
    my $items = $obj->items;
    ok(ref($items) eq 'ARRAY', 'first call returns arrayref');
    
    # Modify it
    push @$items, 'test';
    
    # Second call - should return same arrayref
    my $items2 = $obj->items;
    is_deeply($items2, ['test'], 'second call returns same arrayref with data');
    
    # Same object reference
    is($items, $items2, 'returns same reference');
};

# ============================================
# Test setter_chain - compile and run
# ============================================
subtest 'setter_chain runtime' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->setter_chain('SetterChainTest_name', 'name', 4)
      ->setter_chain('SetterChainTest_age', 'age', 3);
    
    my $code = $b->code;
    
    eval {
        XS::JIT->compile(
            code      => $code,
            name      => 'SetterChainTest',
            cache_dir => $cache_dir,
            functions => {
                'SetterChainTest::set_name' => { source => 'SetterChainTest_name', is_xs_native => 1 },
                'SetterChainTest::set_age'  => { source => 'SetterChainTest_age', is_xs_native => 1 },
            },
        );
    };
    ok(!$@, 'Compile succeeded') or diag $@;
    
    my $obj = bless {}, 'SetterChainTest';
    
    # Chain setters
    my $result = $obj->set_name('Alice')->set_age(30);
    
    is($result, $obj, 'chaining returns self');
    is($obj->{name}, 'Alice', 'name set correctly');
    is($obj->{age}, 30, 'age set correctly');
};

# ============================================
# Test setter_return_value - compile and run
# ============================================
subtest 'setter_return_value runtime' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->setter_return_value('SetterReturnTest_value', 'value', 5);
    
    my $code = $b->code;
    
    eval {
        XS::JIT->compile(
            code      => $code,
            name      => 'SetterReturnTest',
            cache_dir => $cache_dir,
            functions => {
                'SetterReturnTest::set_value' => { source => 'SetterReturnTest_value', is_xs_native => 1 },
            },
        );
    };
    ok(!$@, 'Compile succeeded') or diag $@;
    
    my $obj = bless {}, 'SetterReturnTest';
    
    my $returned = $obj->set_value(42);
    is($returned, 42, 'returns the set value');
    is($obj->{value}, 42, 'value stored correctly');
};

# ============================================
# Test array attribute operations - compile and run
# ============================================
subtest 'attr_push/pop runtime' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->attr_push('ArrayTest_push', 'items', 5)
      ->attr_pop('ArrayTest_pop', 'items', 5)
      ->attr_count('ArrayTest_count', 'items', 5);
    
    my $code = $b->code;
    
    eval {
        XS::JIT->compile(
            code      => $code,
            name      => 'ArrayTest',
            cache_dir => $cache_dir,
            functions => {
                'ArrayTest::push_item'  => { source => 'ArrayTest_push', is_xs_native => 1 },
                'ArrayTest::pop_item'   => { source => 'ArrayTest_pop', is_xs_native => 1 },
                'ArrayTest::item_count' => { source => 'ArrayTest_count', is_xs_native => 1 },
            },
        );
    };
    ok(!$@, 'Compile succeeded') or diag $@;
    
    my $obj = bless { items => [] }, 'ArrayTest';
    
    # Push items
    my $count = $obj->push_item('a', 'b', 'c');
    is($count, 3, 'push returns count');
    is_deeply($obj->{items}, ['a', 'b', 'c'], 'items pushed');
    
    # Count
    is($obj->item_count, 3, 'count returns 3');
    
    # Pop
    my $popped = $obj->pop_item;
    is($popped, 'c', 'pop returns last item');
    is($obj->item_count, 2, 'count is now 2');
};

# ============================================
# Test hash attribute operations - compile and run
# ============================================
subtest 'attr_keys/delete runtime' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->attr_keys('HashTest_keys', 'cache', 5)
      ->attr_delete('HashTest_delete', 'cache', 5)
      ->attr_hash_clear('HashTest_clear', 'cache', 5);
    
    my $code = $b->code;
    
    eval {
        XS::JIT->compile(
            code      => $code,
            name      => 'HashTest',
            cache_dir => $cache_dir,
            functions => {
                'HashTest::cache_keys'   => { source => 'HashTest_keys', is_xs_native => 1 },
                'HashTest::delete_cache' => { source => 'HashTest_delete', is_xs_native => 1 },
                'HashTest::clear_cache'  => { source => 'HashTest_clear', is_xs_native => 1 },
            },
        );
    };
    ok(!$@, 'Compile succeeded') or diag $@;
    
    my $obj = bless { cache => { a => 1, b => 2, c => 3 } }, 'HashTest';
    
    # Keys
    my @keys = sort $obj->cache_keys;
    is_deeply(\@keys, ['a', 'b', 'c'], 'keys returns all keys');
    
    # Delete
    my $deleted = $obj->delete_cache('b');
    is($deleted, 2, 'delete returns deleted value');
    is_deeply($obj->{cache}, { a => 1, c => 3 }, 'b removed');
    
    # Clear
    $obj->clear_cache;
    is_deeply($obj->{cache}, {}, 'cache cleared');
};

# ============================================
# Test slot_lazy_init_dor - compile and run
# ============================================
subtest 'slot_lazy_init_dor runtime' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->slot_lazy_init_dor('SlotLazyTest_cache', 2, 'newRV_noinc((SV*)newHV())', 0);
    
    my $code = $b->code;
    
    eval {
        XS::JIT->compile(
            code      => $code,
            name      => 'SlotLazyTest',
            cache_dir => $cache_dir,
            functions => {
                'SlotLazyTest::cache' => { source => 'SlotLazyTest_cache', is_xs_native => 1 },
            },
        );
    };
    ok(!$@, 'Compile succeeded') or diag $@;
    
    my $obj = bless [undef, undef, undef], 'SlotLazyTest';
    
    # First call - creates hashref
    my $cache = $obj->cache;
    ok(ref($cache) eq 'HASH', 'lazy init creates hashref');
    
    $cache->{foo} = 'bar';
    
    # Second call - returns same ref
    my $cache2 = $obj->cache;
    is($cache2->{foo}, 'bar', 'returns same hashref');
};

done_testing;
