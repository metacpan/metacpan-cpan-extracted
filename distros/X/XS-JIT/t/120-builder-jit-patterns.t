#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test accessor pattern - read only
# ============================================
subtest 'accessor read only' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->accessor('name', { readonly => 1 });
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'PatternTest::ROAccessor',
        cache_dir => $cache_dir,
        functions => {
            'PatternTest::ROAccessor::name' => { source => 'name', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless { name => 'Alice' }, 'PatternTest::ROAccessor';
    is($obj->name, 'Alice', 'readonly accessor reads');
    
    # ro_accessor silently ignores writes (optimized implementation)
    $obj->name('Bob');
    is($obj->name, 'Alice', 'readonly accessor silently ignores write');
};

# ============================================
# Test accessor pattern - read/write
# ============================================
subtest 'accessor read/write' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->accessor('value', { readonly => 0 });
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'PatternTest::RWAccessor',
        cache_dir => $cache_dir,
        functions => {
            'PatternTest::RWAccessor::value' => { source => 'value', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless { value => 100 }, 'PatternTest::RWAccessor';
    is($obj->value, 100, 'rw accessor reads initial');
    
    $obj->value(200);
    is($obj->value, 200, 'rw accessor writes');
    
    my $returned = $obj->value(300);
    is($returned, 300, 'rw accessor returns new value');
};

# ============================================
# Test predicate pattern
# ============================================
subtest 'predicate' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->predicate('enabled');
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'PatternTest::Predicate',
        cache_dir => $cache_dir,
        functions => {
            'PatternTest::Predicate::has_enabled' => { source => 'has_enabled', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj_with = bless { enabled => 1 }, 'PatternTest::Predicate';
    ok($obj_with->has_enabled, 'predicate true when exists');
    
    my $obj_without = bless {}, 'PatternTest::Predicate';
    ok(!$obj_without->has_enabled, 'predicate false when missing');
    
    my $obj_undef = bless { enabled => undef }, 'PatternTest::Predicate';
    ok($obj_undef->has_enabled, 'predicate true when exists but undef');
};

# ============================================
# Test clearer pattern
# ============================================
subtest 'clearer' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->clearer('cache');
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'PatternTest::Clearer',
        cache_dir => $cache_dir,
        functions => {
            'PatternTest::Clearer::clear_cache' => { source => 'clear_cache', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless { cache => 'data', other => 'kept' }, 'PatternTest::Clearer';
    ok(exists $obj->{cache}, 'cache exists before clear');
    
    $obj->clear_cache;
    ok(!exists $obj->{cache}, 'cache removed after clear');
    is($obj->{other}, 'kept', 'other keys preserved');
};

# ============================================
# Test constructor pattern - basic
# ============================================
subtest 'constructor basic' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->constructor('new', []);
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'PatternTest::Constructor',
        cache_dir => $cache_dir,
        functions => {
            'PatternTest::Constructor::new' => { source => 'new', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = PatternTest::Constructor->new;
    isa_ok($obj, 'PatternTest::Constructor');
    is(ref($obj), 'PatternTest::Constructor', 'constructor returns blessed hashref');
};

# ============================================
# Test constructor pattern - with attributes
# ============================================
subtest 'constructor with attributes' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Using the attributes parameter
    $b->xs_function('new_with_attrs')
      ->xs_preamble
      ->raw('SV* class_sv = ST(0);')
      ->raw('STRLEN class_len;')
      ->raw('const char* class = SvPV(class_sv, class_len);')
      ->new_hv('hv')
      ->if('items >= 3')
        ->hv_store('hv', 'name', 4, 'newSVsv(ST(1))')
        ->hv_store('hv', 'value', 5, 'newSVsv(ST(2))')
      ->endif
      ->declare_sv('ref', 'newRV_noinc((SV*)hv)')
      ->raw('sv_bless(ref, gv_stashpvn(class, class_len, GV_ADD));')
      ->return_sv('ref')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'PatternTest::ConstructorAttrs',
        cache_dir => $cache_dir,
        functions => {
            'PatternTest::ConstructorAttrs::new' => { source => 'new_with_attrs', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = PatternTest::ConstructorAttrs->new('test', 42);
    isa_ok($obj, 'PatternTest::ConstructorAttrs');
    is($obj->{name}, 'test', 'constructor attr name');
    is($obj->{value}, 42, 'constructor attr value');
};

# ============================================
# Test combined accessor + predicate + clearer
# ============================================
subtest 'combined patterns' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->accessor('data', { readonly => 0 })
      ->predicate('data')
      ->clearer('data');
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'PatternTest::Combined',
        cache_dir => $cache_dir,
        functions => {
            'PatternTest::Combined::data' => { source => 'data', is_xs_native => 1 },
            'PatternTest::Combined::has_data' => { source => 'has_data', is_xs_native => 1 },
            'PatternTest::Combined::clear_data' => { source => 'clear_data', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless {}, 'PatternTest::Combined';
    
    # Initially no data
    ok(!$obj->has_data, 'no data initially');
    
    # Set data
    $obj->data('hello');
    ok($obj->has_data, 'has data after set');
    is($obj->data, 'hello', 'data value correct');
    
    # Clear data
    $obj->clear_data;
    ok(!$obj->has_data, 'no data after clear');
};

# ============================================
# Test multiple accessors
# ============================================
subtest 'multiple accessors' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->accessor('first_name', { readonly => 0 })
      ->accessor('last_name', { readonly => 0 })
      ->accessor('age', { readonly => 0 });
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'PatternTest::Person',
        cache_dir => $cache_dir,
        functions => {
            'PatternTest::Person::first_name' => { source => 'first_name', is_xs_native => 1 },
            'PatternTest::Person::last_name' => { source => 'last_name', is_xs_native => 1 },
            'PatternTest::Person::age' => { source => 'age', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $person = bless {}, 'PatternTest::Person';
    
    $person->first_name('John');
    $person->last_name('Doe');
    $person->age(30);
    
    is($person->first_name, 'John', 'first_name');
    is($person->last_name, 'Doe', 'last_name');
    is($person->age, 30, 'age');
};

done_testing();
