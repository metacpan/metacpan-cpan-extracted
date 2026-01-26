#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder qw(:types);

# Phase 6 tests: Singleton Pattern
# Tests for singleton_accessor, singleton_reset

my $cache_dir = tempdir(CLEANUP => 1);

# Test 1-4: singleton_accessor code generation
subtest 'singleton_accessor code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->singleton_accessor('sg_instance', 'MySingleton');
    
    my $code = $b->code;
    
    like($code, qr/gv_stashpv\s*\(\s*"MySingleton"/, 
        'gets class stash');
    like($code, qr/gv_fetchpv\s*\(\s*"MySingleton::_instance"/, 
        'fetches instance GV');
    like($code, qr/newHV/, 
        'creates hash for new instance');
    like($code, qr/sv_bless/, 
        'blesses the instance');
};

# Test 5-6: singleton_reset code generation
subtest 'singleton_reset code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->singleton_reset('sg_reset', 'MySingleton');
    
    my $code = $b->code;
    
    like($code, qr/gv_fetchpv\s*\(\s*"MySingleton::_instance"/, 
        'fetches instance GV');
    like($code, qr/sv_setsv.*PL_sv_undef|&PL_sv_undef/, 
        'sets to undef');
};

# Test 7-10: Functional integration - singleton works correctly
subtest 'singleton_accessor integration' => sub {
    my $b = XS::JIT::Builder->new;
    $b->singleton_accessor('sg1_instance', 'Singleton1')
      ->singleton_reset('sg1_reset', 'Singleton1')
      ->rw_accessor('sg1_value', 'value', 5);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Singleton1',
        cache_dir => $cache_dir,
        functions => {
            'Singleton1::instance' => { source => 'sg1_instance', is_xs_native => 1 },
            'Singleton1::reset'    => { source => 'sg1_reset', is_xs_native => 1 },
            'Singleton1::value'    => { source => 'sg1_value', is_xs_native => 1 },
        },
    );
    
    my $obj1 = Singleton1->instance;
    isa_ok($obj1, 'Singleton1', 'returns blessed object');
    
    my $obj2 = Singleton1->instance;
    is($obj1, $obj2, 'returns same instance on repeated calls');
    
    $obj1->value(42);
    is(Singleton1->instance->value, 42, 'data persists on singleton');
    
    # Test reset
    Singleton1->reset;
    my $obj3 = Singleton1->instance;
    isnt($obj1, $obj3, 'reset creates new instance');
    is($obj3->value, undef, 'new instance has fresh data');
};

# Test: Multiple singleton classes are independent
subtest 'multiple singleton classes' => sub {
    my $b = XS::JIT::Builder->new;
    $b->singleton_accessor('sg2_instance', 'Singleton2')
      ->singleton_accessor('sg3_instance', 'Singleton3')
      ->rw_accessor('sg_name', 'name', 4);
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'Singleton2',
        cache_dir => $cache_dir,
        functions => {
            'Singleton2::instance' => { source => 'sg2_instance', is_xs_native => 1 },
            'Singleton3::instance' => { source => 'sg3_instance', is_xs_native => 1 },
            'Singleton2::name'     => { source => 'sg_name', is_xs_native => 1 },
            'Singleton3::name'     => { source => 'sg_name', is_xs_native => 1 },
        },
    );
    
    my $s2 = Singleton2->instance;
    my $s3 = Singleton3->instance;
    
    isnt($s2, $s3, 'different classes have different instances');
    
    $s2->name('Class2');
    $s3->name('Class3');
    
    is(Singleton2->instance->name, 'Class2', 'Singleton2 data independent');
    is(Singleton3->instance->name, 'Class3', 'Singleton3 data independent');
};

done_testing;
