#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use XS::JIT;
use XS::JIT::Builder qw(:types);

# Use temp directory for this test's cache
my $cache_dir = tempdir(CLEANUP => 1);

# ============================================================================
# Test new_with_required
# ============================================================================

subtest 'new_with_required - all required present' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_with_required('new_req', ['name', 'id']);
    $b->rw_accessor('MyReq1_name', 'name', 4);
    $b->rw_accessor('MyReq1_id', 'id', 2);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyReq1',
        cache_dir => $cache_dir,
        functions => {
            'MyReq1::new'  => { source => 'new_req', is_xs_native => 1 },
            'MyReq1::name' => { source => 'MyReq1_name', is_xs_native => 1 },
            'MyReq1::id'   => { source => 'MyReq1_id', is_xs_native => 1 },
        },
    );
    
    my $obj = MyReq1->new(name => 'Alice', id => 42);
    is($obj->name, 'Alice', 'name set');
    is($obj->id, 42, 'id set');
};

subtest 'new_with_required - missing required attr' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_with_required('new_req2', ['name', 'id']);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyReq2',
        cache_dir => $cache_dir,
        functions => {
            'MyReq2::new' => { source => 'new_req2', is_xs_native => 1 },
        },
    );
    
    eval { MyReq2->new(name => 'Bob') };
    like($@, qr/required.*id/i, 'croaks on missing id');
};

subtest 'new_with_required - undef value for required' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_with_required('new_req3', ['name']);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyReq3',
        cache_dir => $cache_dir,
        functions => {
            'MyReq3::new' => { source => 'new_req3', is_xs_native => 1 },
        },
    );
    
    eval { MyReq3->new(name => undef) };
    like($@, qr/required.*name/i, 'croaks on undef required attr');
};

subtest 'new_with_required - hashref argument' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_with_required('new_req4', ['x', 'y']);
    $b->rw_accessor('MyReq4_x', 'x', 1);
    $b->rw_accessor('MyReq4_y', 'y', 1);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyReq4',
        cache_dir => $cache_dir,
        functions => {
            'MyReq4::new' => { source => 'new_req4', is_xs_native => 1 },
            'MyReq4::x'   => { source => 'MyReq4_x', is_xs_native => 1 },
            'MyReq4::y'   => { source => 'MyReq4_y', is_xs_native => 1 },
        },
    );
    
    my $obj = MyReq4->new({ x => 10, y => 20 });
    is($obj->x, 10, 'x from hashref');
    is($obj->y, 20, 'y from hashref');
};

subtest 'new_with_required - single required attr' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_with_required('new_req5', ['value']);
    $b->rw_accessor('MyReq5_value', 'value', 5);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyReq5',
        cache_dir => $cache_dir,
        functions => {
            'MyReq5::new'   => { source => 'new_req5', is_xs_native => 1 },
            'MyReq5::value' => { source => 'MyReq5_value', is_xs_native => 1 },
        },
    );
    
    my $obj = MyReq5->new(value => 'test');
    is($obj->value, 'test', 'single required works');
    
    eval { MyReq5->new() };
    like($@, qr/required.*value/i, 'croaks when missing');
};

subtest 'new_with_required - with optional attrs' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_with_required('new_req6', ['must_have']);
    $b->rw_accessor('MyReq6_must_have', 'must_have', 9);
    $b->rw_accessor('MyReq6_optional', 'optional', 8);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyReq6',
        cache_dir => $cache_dir,
        functions => {
            'MyReq6::new'       => { source => 'new_req6', is_xs_native => 1 },
            'MyReq6::must_have' => { source => 'MyReq6_must_have', is_xs_native => 1 },
            'MyReq6::optional'  => { source => 'MyReq6_optional', is_xs_native => 1 },
        },
    );
    
    my $obj = MyReq6->new(must_have => 'yes', optional => 'maybe');
    is($obj->must_have, 'yes', 'required attr');
    is($obj->optional, 'maybe', 'optional attr');
    
    my $obj2 = MyReq6->new(must_have => 'only');
    is($obj2->must_have, 'only', 'required without optional');
    is($obj2->optional, undef, 'optional is undef');
};

# ============================================================================
# Test rw_accessor_typed
# ============================================================================

subtest 'rw_accessor_typed - TYPE_INT valid' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed1');
    $b->rw_accessor_typed('MyTyped1_count', 'count', 5, TYPE_INT, 'count must be an integer');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped1',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped1::new'   => { source => 'new_typed1', is_xs_native => 1 },
            'MyTyped1::count' => { source => 'MyTyped1_count', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped1->new();
    $obj->count(42);
    is($obj->count, 42, 'int accepted');
    
    $obj->count(-10);
    is($obj->count, -10, 'negative int accepted');
    
    $obj->count(0);
    is($obj->count, 0, 'zero accepted');
};

subtest 'rw_accessor_typed - TYPE_INT invalid' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed2');
    $b->rw_accessor_typed('MyTyped2_age', 'age', 3, TYPE_INT, 'age must be an integer');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped2',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped2::new' => { source => 'new_typed2', is_xs_native => 1 },
            'MyTyped2::age' => { source => 'MyTyped2_age', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped2->new();
    
    eval { $obj->age('hello') };
    like($@, qr/age must be an integer/, 'rejects string');
    
    eval { $obj->age(3.14) };
    like($@, qr/age must be an integer/, 'rejects float');
};

subtest 'rw_accessor_typed - TYPE_NUM' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed3');
    $b->rw_accessor_typed('MyTyped3_price', 'price', 5, TYPE_NUM, 'price must be numeric');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped3',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped3::new'   => { source => 'new_typed3', is_xs_native => 1 },
            'MyTyped3::price' => { source => 'MyTyped3_price', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped3->new();
    
    $obj->price(3.14);
    is($obj->price, 3.14, 'float accepted');
    
    $obj->price(42);
    is($obj->price, 42, 'int as num accepted');
    
    eval { $obj->price('not a number') };
    like($@, qr/price must be numeric/, 'rejects non-numeric string');
};

subtest 'rw_accessor_typed - TYPE_STR' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed4');
    $b->rw_accessor_typed('MyTyped4_label', 'label', 5, TYPE_STR, 'label must be a string');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped4',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped4::new'   => { source => 'new_typed4', is_xs_native => 1 },
            'MyTyped4::label' => { source => 'MyTyped4_label', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped4->new();
    
    $obj->label('hello');
    is($obj->label, 'hello', 'string accepted');
    
    $obj->label('123');
    is($obj->label, '123', 'numeric string accepted');
    
    eval { $obj->label([1,2,3]) };
    like($@, qr/label must be a string/, 'rejects arrayref');
};

subtest 'rw_accessor_typed - TYPE_ARRAYREF' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed5');
    $b->rw_accessor_typed('MyTyped5_items', 'items', 5, TYPE_ARRAYREF, 'items must be an arrayref');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped5',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped5::new'   => { source => 'new_typed5', is_xs_native => 1 },
            'MyTyped5::items' => { source => 'MyTyped5_items', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped5->new();
    
    $obj->items([1, 2, 3]);
    is_deeply($obj->items, [1, 2, 3], 'arrayref accepted');
    
    eval { $obj->items({a => 1}) };
    like($@, qr/items must be an arrayref/, 'rejects hashref');
    
    eval { $obj->items('string') };
    like($@, qr/items must be an arrayref/, 'rejects string');
};

subtest 'rw_accessor_typed - TYPE_HASHREF' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed6');
    $b->rw_accessor_typed('MyTyped6_config', 'config', 6, TYPE_HASHREF, 'config must be a hashref');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped6',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped6::new'    => { source => 'new_typed6', is_xs_native => 1 },
            'MyTyped6::config' => { source => 'MyTyped6_config', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped6->new();
    
    $obj->config({a => 1, b => 2});
    is_deeply($obj->config, {a => 1, b => 2}, 'hashref accepted');
    
    eval { $obj->config([1, 2]) };
    like($@, qr/config must be a hashref/, 'rejects arrayref');
};

subtest 'rw_accessor_typed - TYPE_CODEREF' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed7');
    $b->rw_accessor_typed('MyTyped7_callback', 'callback', 8, TYPE_CODEREF, 'callback must be a coderef');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped7',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped7::new'      => { source => 'new_typed7', is_xs_native => 1 },
            'MyTyped7::callback' => { source => 'MyTyped7_callback', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped7->new();
    
    my $cb = sub { 'called' };
    $obj->callback($cb);
    is($obj->callback->(), 'called', 'coderef accepted and callable');
    
    eval { $obj->callback('not code') };
    like($@, qr/callback must be a coderef/, 'rejects string');
};

subtest 'rw_accessor_typed - TYPE_OBJECT' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed8');
    $b->rw_accessor_typed('MyTyped8_child', 'child', 5, TYPE_OBJECT, 'child must be a blessed object');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped8',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped8::new'   => { source => 'new_typed8', is_xs_native => 1 },
            'MyTyped8::child' => { source => 'MyTyped8_child', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped8->new();
    
    my $child = bless {}, 'SomeClass';
    $obj->child($child);
    is(ref($obj->child), 'SomeClass', 'blessed object accepted');
    
    eval { $obj->child({}) };
    like($@, qr/child must be a blessed object/, 'rejects unblessed hashref');
};

subtest 'rw_accessor_typed - TYPE_DEFINED' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed9');
    $b->rw_accessor_typed('MyTyped9_val', 'val', 3, TYPE_DEFINED, 'val cannot be undef');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped9',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped9::new' => { source => 'new_typed9', is_xs_native => 1 },
            'MyTyped9::val' => { source => 'MyTyped9_val', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped9->new();
    
    $obj->val(0);
    is($obj->val, 0, 'zero is defined');
    
    $obj->val('');
    is($obj->val, '', 'empty string is defined');
    
    eval { $obj->val(undef) };
    like($@, qr/val cannot be undef/, 'rejects undef');
};

subtest 'rw_accessor_typed - undef bypasses type check' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new_typed10');
    $b->rw_accessor_typed('MyTyped10_num', 'num', 3, TYPE_INT, 'num must be an integer');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'MyTyped10',
        cache_dir => $cache_dir,
        functions => {
            'MyTyped10::new' => { source => 'new_typed10', is_xs_native => 1 },
            'MyTyped10::num' => { source => 'MyTyped10_num', is_xs_native => 1 },
        },
    );
    
    my $obj = MyTyped10->new();
    
    $obj->num(42);
    is($obj->num, 42, 'int set');
    
    # undef should be allowed (clears the value)
    $obj->num(undef);
    is($obj->num, undef, 'undef accepted and clears value');
};

done_testing();
