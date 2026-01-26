#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test check_items exact
# ============================================
subtest 'check_items exact' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_check_items_exact')
      ->xs_preamble
      ->check_items(2, 2, '$a, $b')
      ->return_iv('items')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Exact',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Exact::need_two' => { source => 'test_check_items_exact', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(CheckTest::Exact::need_two(1, 2), 2, 'check_items passes with correct count');
    
    eval { CheckTest::Exact::need_two(1) };
    like($@, qr/Usage:/, 'check_items fails with too few');
    
    eval { CheckTest::Exact::need_two(1, 2, 3) };
    like($@, qr/Usage:/, 'check_items fails with too many');
};

# ============================================
# Test check_items range
# ============================================
subtest 'check_items range' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_check_items_range')
      ->xs_preamble
      ->check_items(1, 3, '$required, $opt1?, $opt2?')
      ->return_iv('items')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Range',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Range::flexible' => { source => 'test_check_items_range', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(CheckTest::Range::flexible(1), 1, 'check_items range with 1');
    is(CheckTest::Range::flexible(1, 2), 2, 'check_items range with 2');
    is(CheckTest::Range::flexible(1, 2, 3), 3, 'check_items range with 3');
    
    eval { CheckTest::Range::flexible() };
    like($@, qr/Usage:/, 'check_items range fails with 0');
    
    eval { CheckTest::Range::flexible(1, 2, 3, 4) };
    like($@, qr/Usage:/, 'check_items range fails with 4');
};

# ============================================
# Test check_items minimum only
# ============================================
subtest 'check_items minimum only' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_check_items_min')
      ->xs_preamble
      ->check_items(1, -1, '$self, @rest')
      ->return_iv('items')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Min',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Min::at_least_one' => { source => 'test_check_items_min', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(CheckTest::Min::at_least_one(1), 1, 'check_items min with 1');
    is(CheckTest::Min::at_least_one(1, 2, 3, 4, 5), 5, 'check_items min with many');
    
    eval { CheckTest::Min::at_least_one() };
    like($@, qr/Usage:/, 'check_items min fails with 0');
};

# ============================================
# Test check_defined
# ============================================
subtest 'check_defined' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_check_defined')
      ->xs_preamble
      ->check_defined('ST(0)', 'Value must be defined')
      ->return_yes
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Defined',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Defined::require_val' => { source => 'test_check_defined', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    ok(CheckTest::Defined::require_val(1), 'check_defined passes with value');
    ok(CheckTest::Defined::require_val('hello'), 'check_defined passes with string');
    ok(CheckTest::Defined::require_val(0), 'check_defined passes with 0');
    
    eval { CheckTest::Defined::require_val(undef) };
    like($@, qr/must be defined/, 'check_defined fails with undef');
};

# ============================================
# Test check_hashref
# ============================================
subtest 'check_hashref' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_check_hashref')
      ->xs_preamble
      ->check_hashref('ST(0)', 'Expected a hash reference')
      ->declare_hv('hv', '(HV*)SvRV(ST(0))')
      ->return_iv('HvKEYS(hv)')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Hashref',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Hashref::count_keys' => { source => 'test_check_hashref', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(CheckTest::Hashref::count_keys({ a => 1, b => 2 }), 2, 'check_hashref passes with hashref');
    is(CheckTest::Hashref::count_keys({}), 0, 'check_hashref passes with empty hashref');
    
    eval { CheckTest::Hashref::count_keys([1, 2, 3]) };
    like($@, qr/hash reference/, 'check_hashref fails with arrayref');
    
    eval { CheckTest::Hashref::count_keys('string') };
    like($@, qr/hash reference/, 'check_hashref fails with string');
};

# ============================================
# Test check_arrayref
# ============================================
subtest 'check_arrayref' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_check_arrayref')
      ->xs_preamble
      ->check_arrayref('ST(0)', 'Expected an array reference')
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->return_iv('av_len(av) + 1')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Arrayref',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Arrayref::count_elems' => { source => 'test_check_arrayref', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(CheckTest::Arrayref::count_elems([1, 2, 3]), 3, 'check_arrayref passes with arrayref');
    is(CheckTest::Arrayref::count_elems([]), 0, 'check_arrayref passes with empty arrayref');
    
    eval { CheckTest::Arrayref::count_elems({ a => 1 }) };
    like($@, qr/array reference/, 'check_arrayref fails with hashref');
    
    eval { CheckTest::Arrayref::count_elems('string') };
    like($@, qr/array reference/, 'check_arrayref fails with string');
};

# ============================================
# Test croak
# ============================================
subtest 'croak' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_croak')
      ->xs_preamble
      ->if('SvIV(ST(0)) < 0')
        ->croak('Negative values not allowed')
      ->endif
      ->return_iv('SvIV(ST(0))')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Croak',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Croak::positive_only' => { source => 'test_croak', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(CheckTest::Croak::positive_only(5), 5, 'croak not triggered');
    is(CheckTest::Croak::positive_only(0), 0, 'croak not triggered for 0');
    
    eval { CheckTest::Croak::positive_only(-1) };
    like($@, qr/Negative values not allowed/, 'croak triggers');
};

# ============================================
# Test warn
# ============================================
subtest 'warn' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_warn')
      ->xs_preamble
      ->if('SvIV(ST(0)) > 100')
        ->warn('Value exceeds 100')
      ->endif
      ->return_iv('SvIV(ST(0))')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Warn',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Warn::with_warning' => { source => 'test_warn', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(CheckTest::Warn::with_warning(50), 50, 'warn not triggered');
    
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };
    is(CheckTest::Warn::with_warning(150), 150, 'returns value with warning');
    like($warning, qr/exceeds 100/, 'warn triggered');
};

# ============================================
# Test croak_usage
# ============================================
subtest 'croak_usage' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_croak_usage')
      ->xs_preamble
      ->if('items != 2')
        ->croak_usage('$a, $b')
      ->endif
      ->return_iv('SvIV(ST(0)) + SvIV(ST(1))')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'CheckTest::Usage',
        cache_dir => $cache_dir,
        functions => {
            'CheckTest::Usage::add' => { source => 'test_croak_usage', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(CheckTest::Usage::add(3, 4), 7, 'croak_usage not triggered');
    
    eval { CheckTest::Usage::add(1) };
    like($@, qr/Usage:/, 'croak_usage triggers');
};

done_testing();
