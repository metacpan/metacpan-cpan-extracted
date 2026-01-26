#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test return_iv
# ============================================
subtest 'return_iv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_iv')
      ->xs_preamble
      ->declare('IV', 'result', 'SvIV(ST(0)) * 2')
      ->return_iv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ReturnTest::IV',
        cache_dir => $cache_dir,
        functions => {
            'ReturnTest::IV::double' => { source => 'test_return_iv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ReturnTest::IV::double(5), 10, 'return_iv works');
    is(ReturnTest::IV::double(-3), -6, 'return_iv with negative');
    is(ReturnTest::IV::double(0), 0, 'return_iv with zero');
};

# ============================================
# Test return_nv
# ============================================
subtest 'return_nv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_nv')
      ->xs_preamble
      ->declare('NV', 'result', 'SvNV(ST(0)) / 2.0')
      ->return_nv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ReturnTest::NV',
        cache_dir => $cache_dir,
        functions => {
            'ReturnTest::NV::half' => { source => 'test_return_nv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ReturnTest::NV::half(10), 5, 'return_nv works');
    is(ReturnTest::NV::half(5), 2.5, 'return_nv with decimal result');
};

# ============================================
# Test return_pv
# ============================================
subtest 'return_pv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_pv')
      ->xs_preamble
      ->return_pv('"hello world"', '11')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ReturnTest::PV',
        cache_dir => $cache_dir,
        functions => {
            'ReturnTest::PV::greeting' => { source => 'test_return_pv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ReturnTest::PV::greeting(), 'hello world', 'return_pv works');
};

# ============================================
# Test return_sv
# ============================================
subtest 'return_sv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_sv')
      ->xs_preamble
      ->line('SV* result = sv_2mortal(newSViv(42));')
      ->return_sv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ReturnTest::SV',
        cache_dir => $cache_dir,
        functions => {
            'ReturnTest::SV::answer' => { source => 'test_return_sv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ReturnTest::SV::answer(), 42, 'return_sv works');
};

# ============================================
# Test return_yes
# ============================================
subtest 'return_yes' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_yes')
      ->xs_preamble
      ->return_yes
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ReturnTest::Yes',
        cache_dir => $cache_dir,
        functions => {
            'ReturnTest::Yes::always_true' => { source => 'test_return_yes', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    ok(ReturnTest::Yes::always_true(), 'return_yes returns true');
    is(ReturnTest::Yes::always_true(), 1, 'return_yes returns 1');
};

# ============================================
# Test return_no
# ============================================
subtest 'return_no' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_no')
      ->xs_preamble
      ->return_no
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ReturnTest::No',
        cache_dir => $cache_dir,
        functions => {
            'ReturnTest::No::always_false' => { source => 'test_return_no', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    ok(!ReturnTest::No::always_false(), 'return_no returns false');
};

# ============================================
# Test return_self
# ============================================
subtest 'return_self' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_self')
      ->xs_preamble
      ->get_self
      ->return_self
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ReturnTest::Self',
        cache_dir => $cache_dir,
        functions => {
            'ReturnTest::Self::chain' => { source => 'test_return_self', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless {}, 'ReturnTest::Self';
    my $result = $obj->chain;
    is($result, $obj, 'return_self returns $self');
};

# ============================================
# Test xs_return_undef
# ============================================
subtest 'xs_return_undef' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_return_undef')
      ->xs_preamble
      ->xs_return_undef
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ReturnTest::Undef',
        cache_dir => $cache_dir,
        functions => {
            'ReturnTest::Undef::nothing' => { source => 'test_return_undef', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    ok(!defined ReturnTest::Undef::nothing(), 'xs_return_undef returns undef');
};

done_testing();
