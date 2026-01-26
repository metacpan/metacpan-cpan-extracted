#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test declare_sv
# ============================================
subtest 'declare_sv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_declare_sv')
      ->xs_preamble
      ->declare_sv('input', 'ST(0)')
      ->declare_sv('copy', 'newSVsv(input)')
      ->raw('sv_catpvs(copy, " modified");')
      ->return_sv('copy')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::SV',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::SV::modify' => { source => 'test_declare_sv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(DeclareTest::SV::modify('hello'), 'hello modified', 'declare_sv works');
};

# ============================================
# Test declare_iv
# ============================================
subtest 'declare_iv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_declare_iv')
      ->xs_preamble
      ->declare_iv('a', 'SvIV(ST(0))')
      ->declare_iv('b', 'SvIV(ST(1))')
      ->declare_iv('result', 'a * b')
      ->return_iv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::IV',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::IV::multiply' => { source => 'test_declare_iv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(DeclareTest::IV::multiply(6, 7), 42, 'declare_iv works');
    is(DeclareTest::IV::multiply(-5, 3), -15, 'declare_iv negative');
};

# ============================================
# Test declare_nv
# ============================================
subtest 'declare_nv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_declare_nv')
      ->xs_preamble
      ->declare_nv('a', 'SvNV(ST(0))')
      ->declare_nv('b', 'SvNV(ST(1))')
      ->declare_nv('result', 'a / b')
      ->return_nv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::NV',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::NV::divide' => { source => 'test_declare_nv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(DeclareTest::NV::divide(10.0, 4.0), 2.5, 'declare_nv works');
    is(DeclareTest::NV::divide(1.0, 3.0), 1.0/3.0, 'declare_nv precision');
};

# ============================================
# Test declare_pv
# ============================================
subtest 'declare_pv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_declare_pv')
      ->xs_preamble
      ->raw('STRLEN len;')
      ->declare_pv('str', 'SvPV(ST(0), len)')
      ->declare_iv('length', '(IV)len')
      ->return_iv('length')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::PV',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::PV::strlen' => { source => 'test_declare_pv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(DeclareTest::PV::strlen('hello'), 5, 'declare_pv works');
    is(DeclareTest::PV::strlen(''), 0, 'declare_pv empty');
    is(DeclareTest::PV::strlen('longer string'), 13, 'declare_pv longer');
};

# ============================================
# Test declare_hv
# ============================================
subtest 'declare_hv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_declare_hv')
      ->xs_preamble
      ->declare_hv('hv', '(HV*)SvRV(ST(0))')
      ->declare_iv('count', 'HvKEYS(hv)')
      ->return_iv('count')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::HV',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::HV::key_count' => { source => 'test_declare_hv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(DeclareTest::HV::key_count({ a => 1, b => 2, c => 3 }), 3, 'declare_hv works');
    is(DeclareTest::HV::key_count({}), 0, 'declare_hv empty');
};

# ============================================
# Test declare_av
# ============================================
subtest 'declare_av' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_declare_av')
      ->xs_preamble
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->declare_iv('len', 'av_len(av) + 1')
      ->return_iv('len')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::AV',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::AV::elem_count' => { source => 'test_declare_av', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(DeclareTest::AV::elem_count([1, 2, 3, 4]), 4, 'declare_av works');
    is(DeclareTest::AV::elem_count([]), 0, 'declare_av empty');
};

# ============================================
# Test assign
# ============================================
subtest 'assign' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_assign')
      ->xs_preamble
      ->declare_iv('x', '0')
      ->assign('x', 'SvIV(ST(0)) + 100')
      ->return_iv('x')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::Assign',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::Assign::add100' => { source => 'test_assign', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(DeclareTest::Assign::add100(5), 105, 'assign works');
    is(DeclareTest::Assign::add100(0), 100, 'assign with zero');
};

# ============================================
# Test combined declarations in function
# ============================================
subtest 'combined declarations' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_combined_decl')
      ->xs_preamble
      ->declare_iv('count', '0')
      ->declare_nv('sum', '0.0')
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->declare_iv('len', 'av_len(av) + 1')
      ->for('IV i = 0', 'i < len', 'i++')
        ->av_fetch('av', 'i', 'elem')
        ->if('elem != NULL')
          ->raw('sum += SvNV(*elem);')
          ->raw('count++;')
        ->endif
      ->endfor
      ->if('count > 0')
        ->return_nv('sum / (NV)count')
      ->endif
      ->return_nv('0.0')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::Average',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::Average::compute' => { source => 'test_combined_decl', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(DeclareTest::Average::compute([1, 2, 3, 4, 5]), 3, 'average of 1-5');
    is(DeclareTest::Average::compute([10, 20]), 15, 'average of 10,20');
    is(DeclareTest::Average::compute([]), 0, 'average of empty');
};

# ============================================
# Test new_hv
# ============================================
subtest 'new_hv' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_new_hv')
      ->xs_preamble
      ->new_hv('hv')
      ->raw('hv_store(hv, "foo", 3, newSViv(42), 0);')
      ->raw('hv_store(hv, "bar", 3, newSVpvs("hello"), 0);')
      ->return_sv('newRV_noinc((SV*)hv)')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::NewHV',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::NewHV::make_hash' => { source => 'test_new_hv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $result = DeclareTest::NewHV::make_hash();
    is(ref($result), 'HASH', 'new_hv returns hashref');
    is($result->{foo}, 42, 'new_hv foo value');
    is($result->{bar}, 'hello', 'new_hv bar value');
};

# ============================================
# Test new_av
# ============================================
subtest 'new_av' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_new_av')
      ->xs_preamble
      ->declare_iv('n', 'SvIV(ST(0))')
      ->new_av('av')
      ->for('IV i = 0', 'i < n', 'i++')
        ->av_push('av', 'newSViv(i * i)')
      ->endfor
      ->return_sv('newRV_noinc((SV*)av)')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'DeclareTest::NewAV',
        cache_dir => $cache_dir,
        functions => {
            'DeclareTest::NewAV::squares' => { source => 'test_new_av', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is_deeply(DeclareTest::NewAV::squares(5), [0, 1, 4, 9, 16], 'new_av squares');
    is_deeply(DeclareTest::NewAV::squares(0), [], 'new_av empty');
};

done_testing();
