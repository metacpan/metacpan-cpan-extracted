#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test sv_to_iv
# ============================================
subtest 'sv_to_iv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_sv_to_iv')
      ->xs_preamble
      ->sv_to_iv('val', 'ST(0)')
      ->declare('IV', 'result', 'val * 3')
      ->return_iv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ConvTest::IV',
        cache_dir => $cache_dir,
        functions => {
            'ConvTest::IV::triple' => { source => 'test_sv_to_iv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ConvTest::IV::triple(7), 21, 'sv_to_iv works');
    is(ConvTest::IV::triple("5"), 15, 'sv_to_iv with string');
};

# ============================================
# Test sv_to_nv
# ============================================
subtest 'sv_to_nv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_sv_to_nv')
      ->xs_preamble
      ->sv_to_nv('val', 'ST(0)')
      ->declare('NV', 'result', 'val * 1.5')
      ->return_nv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ConvTest::NV',
        cache_dir => $cache_dir,
        functions => {
            'ConvTest::NV::scale' => { source => 'test_sv_to_nv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ConvTest::NV::scale(10), 15, 'sv_to_nv works');
    is(ConvTest::NV::scale(2.5), 3.75, 'sv_to_nv with decimal');
};

# ============================================
# Test sv_to_pv
# ============================================
subtest 'sv_to_pv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_sv_to_pv')
      ->xs_preamble
      ->sv_to_pv('str', 'len', 'ST(0)')
      ->return_iv('(IV)len')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ConvTest::PV',
        cache_dir => $cache_dir,
        functions => {
            'ConvTest::PV::strlen' => { source => 'test_sv_to_pv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ConvTest::PV::strlen('hello'), 5, 'sv_to_pv extracts length');
    is(ConvTest::PV::strlen(''), 0, 'sv_to_pv with empty string');
    is(ConvTest::PV::strlen('test string'), 11, 'sv_to_pv with spaces');
};

# ============================================
# Test sv_to_pv without length
# ============================================
subtest 'sv_to_pv without length' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_sv_to_pv_nolen')
      ->xs_preamble
      ->sv_to_pv('str', undef, 'ST(0)')
      ->line('IV result = str[0];')  # Get first char ASCII value
      ->return_iv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ConvTest::PVNolen',
        cache_dir => $cache_dir,
        functions => {
            'ConvTest::PVNolen::first_ord' => { source => 'test_sv_to_pv_nolen', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ConvTest::PVNolen::first_ord('A'), ord('A'), 'sv_to_pv nolen works');
    is(ConvTest::PVNolen::first_ord('hello'), ord('h'), 'sv_to_pv nolen first char');
};

# ============================================
# Test sv_to_bool
# ============================================
subtest 'sv_to_bool' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_sv_to_bool')
      ->xs_preamble
      ->sv_to_bool('flag', 'ST(0)')
      ->if('flag')
        ->return_iv('100')
      ->else
        ->return_iv('0')
      ->endif
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ConvTest::Bool',
        cache_dir => $cache_dir,
        functions => {
            'ConvTest::Bool::check' => { source => 'test_sv_to_bool', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ConvTest::Bool::check(1), 100, 'sv_to_bool true');
    is(ConvTest::Bool::check(0), 0, 'sv_to_bool false');
    is(ConvTest::Bool::check(''), 0, 'sv_to_bool empty string is false');
    is(ConvTest::Bool::check('hello'), 100, 'sv_to_bool non-empty string is true');
};

# ============================================
# Test new_sv_iv
# ============================================
subtest 'new_sv_iv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_new_sv_iv')
      ->xs_preamble
      ->new_sv_iv('result', 'SvIV(ST(0)) + 1000')
      ->mortal('result')
      ->return_sv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'NewSV::IV',
        cache_dir => $cache_dir,
        functions => {
            'NewSV::IV::add1000' => { source => 'test_new_sv_iv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(NewSV::IV::add1000(42), 1042, 'new_sv_iv works');
    is(NewSV::IV::add1000(-500), 500, 'new_sv_iv with negative');
};

# ============================================
# Test new_sv_nv
# ============================================
subtest 'new_sv_nv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_new_sv_nv')
      ->xs_preamble
      ->new_sv_nv('result', 'SvNV(ST(0)) * 3.14159')
      ->mortal('result')
      ->return_sv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'NewSV::NV',
        cache_dir => $cache_dir,
        functions => {
            'NewSV::NV::times_pi' => { source => 'test_new_sv_nv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $result = NewSV::NV::times_pi(2);
    ok($result > 6.28 && $result < 6.29, 'new_sv_nv works');
};

# ============================================
# Test new_sv_pv
# ============================================
subtest 'new_sv_pv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_new_sv_pv')
      ->xs_preamble
      ->new_sv_pv('result', 'test', 4)
      ->mortal('result')
      ->return_sv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'NewSV::PV',
        cache_dir => $cache_dir,
        functions => {
            'NewSV::PV::fixed' => { source => 'test_new_sv_pv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(NewSV::PV::fixed(), 'test', 'new_sv_pv works');
};

done_testing();
