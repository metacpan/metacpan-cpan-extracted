#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test get_self basic
# ============================================
subtest 'get_self basic' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_get_self')
      ->xs_preamble
      ->get_self
      ->return_sv('self')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'SelfTest::Basic',
        cache_dir => $cache_dir,
        functions => {
            'SelfTest::Basic::get_me' => { source => 'test_get_self', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless { value => 42 }, 'SelfTest::Basic';
    my $result = $obj->get_me;
    is($result, $obj, 'get_self returns same object');
    is($result->{value}, 42, 'get_self object intact');
};

# ============================================
# Test get_self_hv
# ============================================
subtest 'get_self_hv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_get_self_hv')
      ->xs_preamble
      ->get_self_hv
      ->declare_iv('count', 'HvKEYS(hv)')
      ->return_iv('count')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'SelfTest::HV',
        cache_dir => $cache_dir,
        functions => {
            'SelfTest::HV::attr_count' => { source => 'test_get_self_hv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless { a => 1, b => 2, c => 3 }, 'SelfTest::HV';
    is($obj->attr_count, 3, 'get_self_hv accesses hash');
    
    $obj->{d} = 4;
    is($obj->attr_count, 4, 'get_self_hv sees new key');
};

# ============================================
# Test method_start
# ============================================
subtest 'method_start' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_method_start')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'value', 5, 'val_ptr')
      ->if('val_ptr != NULL')
        ->return_iv('SvIV(*val_ptr)')
      ->endif
      ->return_iv('0')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'SelfTest::MethodStart',
        cache_dir => $cache_dir,
        functions => {
            'SelfTest::MethodStart::get_value' => { source => 'test_method_start', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless { value => 99 }, 'SelfTest::MethodStart';
    is($obj->get_value, 99, 'method_start works');
};

# ============================================
# Test mortal
# ============================================
subtest 'mortal' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_mortal')
      ->xs_preamble
      ->declare_sv('result', 'newSVpvs("temporary")')
      ->mortal('result')
      ->return_sv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'SelfTest::Mortal',
        cache_dir => $cache_dir,
        functions => {
            'SelfTest::Mortal::get_temp' => { source => 'test_mortal', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $result = SelfTest::Mortal::get_temp();
    is($result, 'temporary', 'mortal sv returned correctly');
};

# ============================================
# Test return_self
# ============================================
subtest 'return_self' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_self')
      ->xs_preamble
      ->get_self_hv
      ->hv_store('hv', 'modified', '8', 'newSViv(1)')
      ->return_self
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'SelfTest::ReturnSelf',
        cache_dir => $cache_dir,
        functions => {
            'SelfTest::ReturnSelf::modify' => { source => 'test_return_self', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless {}, 'SelfTest::ReturnSelf';
    my $result = $obj->modify;
    is($result, $obj, 'return_self returns same object');
    ok($obj->{modified}, 'return_self after modification');
};

# ============================================
# Test chained method calls
# ============================================
subtest 'chained methods with return_self' => sub {
    my $builder = XS::JIT::Builder->new;
    
    # setter method
    $builder->xs_function('test_chain_set')
      ->xs_preamble
      ->get_self_hv
      ->declare_sv('key_sv', 'ST(1)')
      ->declare_sv('val_sv', 'ST(2)')
      ->raw('STRLEN key_len;')
      ->raw('const char* key = SvPV(key_sv, key_len);')
      ->hv_store_sv('hv', 'key', 'key_len', 'newSVsv(val_sv)')
      ->return_self
      ->xs_end;
    
    # getter method  
    $builder->xs_function('test_chain_get')
      ->xs_preamble
      ->get_self_hv
      ->declare_sv('key_sv', 'ST(1)')
      ->raw('STRLEN key_len;')
      ->raw('const char* key = SvPV(key_sv, key_len);')
      ->hv_fetch_sv('hv', 'key', 'key_len', 'val_ptr')
      ->if('val_ptr != NULL')
        ->return_sv('*val_ptr')
      ->endif
      ->return_undef
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $builder->code,
        name      => 'SelfTest::Chain',
        cache_dir => $cache_dir,
        functions => {
            'SelfTest::Chain::set' => { source => 'test_chain_set', is_xs_native => 1 },
            'SelfTest::Chain::get' => { source => 'test_chain_get', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless {}, 'SelfTest::Chain';
    
    # Test chaining
    my $result = $obj->set('foo', 1)->set('bar', 2)->set('baz', 3);
    is($result, $obj, 'chaining returns same object');
    
    is($obj->get('foo'), 1, 'chained set foo');
    is($obj->get('bar'), 2, 'chained set bar');
    is($obj->get('baz'), 3, 'chained set baz');
};

# ============================================
# Test self with inheritance check
# ============================================
subtest 'self with different blessed class' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_self_class')
      ->xs_preamble
      ->get_self
      ->raw('const char* class = sv_reftype(SvRV(self), TRUE);')
      ->return_pv('class')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'SelfTest::Class',
        cache_dir => $cache_dir,
        functions => {
            'SelfTest::Class::get_class' => { source => 'test_self_class', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless {}, 'SelfTest::Class';
    is($obj->get_class, 'SelfTest::Class', 'get_class returns blessed name');
    
    # Test with subclass
    {
        package SelfTest::SubClass;
        our @ISA = ('SelfTest::Class');
    }
    my $sub_obj = bless {}, 'SelfTest::SubClass';
    is($sub_obj->get_class, 'SelfTest::SubClass', 'subclass name returned');
};

done_testing();
