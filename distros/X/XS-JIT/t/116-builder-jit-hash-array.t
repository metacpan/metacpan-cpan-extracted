#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test hv_fetch with dynamic key
# ============================================
subtest 'hv_fetch_sv dynamic key' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_hv_fetch_sv')
      ->xs_preamble
      ->declare_hv('hv', '(HV*)SvRV(ST(0))')
      ->declare_sv('key_sv', 'ST(1)')
      ->raw('STRLEN key_len;')
      ->raw('const char* key = SvPV(key_sv, key_len);')
      ->hv_fetch_sv('hv', 'key', 'key_len', 'fetched')
      ->if('fetched != NULL')
        ->return_sv('*fetched')
      ->endif
      ->xs_return_undef
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'HashTest::FetchSV',
        cache_dir => $cache_dir,
        functions => {
            'HashTest::FetchSV::get' => { source => 'test_hv_fetch_sv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $hash = { foo => 42, bar => 'hello' };
    is(HashTest::FetchSV::get($hash, 'foo'), 42, 'hv_fetch_sv found integer');
    is(HashTest::FetchSV::get($hash, 'bar'), 'hello', 'hv_fetch_sv found string');
    is(HashTest::FetchSV::get($hash, 'missing'), undef, 'hv_fetch_sv returns undef for missing');
};

# ============================================
# Test hv_fetch with literal key
# ============================================
subtest 'hv_fetch literal key' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_hv_fetch_lit')
      ->xs_preamble
      ->declare_hv('hv', '(HV*)SvRV(ST(0))')
      ->hv_fetch('hv', 'foo', 3, 'fetched')
      ->if('fetched != NULL')
        ->return_sv('*fetched')
      ->endif
      ->xs_return_undef
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'HashTest::FetchLit',
        cache_dir => $cache_dir,
        functions => {
            'HashTest::FetchLit::get_foo' => { source => 'test_hv_fetch_lit', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $hash = { foo => 42, bar => 'hello' };
    is(HashTest::FetchLit::get_foo($hash), 42, 'hv_fetch literal key works');
    is(HashTest::FetchLit::get_foo({ bar => 1 }), undef, 'hv_fetch literal missing');
};

# ============================================
# Test hv_store with dynamic key
# ============================================
subtest 'hv_store_sv dynamic key' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_hv_store_sv')
      ->xs_preamble
      ->declare_hv('hv', '(HV*)SvRV(ST(0))')
      ->declare_sv('key_sv', 'ST(1)')
      ->declare_sv('val', 'newSVsv(ST(2))')
      ->raw('STRLEN key_len;')
      ->raw('const char* key = SvPV(key_sv, key_len);')
      ->hv_store_sv('hv', 'key', 'key_len', 'val')
      ->return_yes
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'HashTest::StoreSV',
        cache_dir => $cache_dir,
        functions => {
            'HashTest::StoreSV::set' => { source => 'test_hv_store_sv', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $hash = {};
    ok(HashTest::StoreSV::set($hash, 'key1', 100), 'hv_store_sv returns true');
    is($hash->{key1}, 100, 'hv_store_sv stored value');
    
    HashTest::StoreSV::set($hash, 'key2', 'string');
    is($hash->{key2}, 'string', 'hv_store_sv stored string');
};

# ============================================
# Test hv_store with literal key
# ============================================
subtest 'hv_store literal key' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_hv_store_lit')
      ->xs_preamble
      ->declare_hv('hv', '(HV*)SvRV(ST(0))')
      ->declare_sv('val', 'newSVsv(ST(1))')
      ->hv_store('hv', 'fixed_key', 9, 'val')
      ->return_yes
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'HashTest::StoreLit',
        cache_dir => $cache_dir,
        functions => {
            'HashTest::StoreLit::set_fixed' => { source => 'test_hv_store_lit', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $hash = {};
    ok(HashTest::StoreLit::set_fixed($hash, 'myvalue'), 'hv_store literal returns true');
    is($hash->{fixed_key}, 'myvalue', 'hv_store literal stored value');
};

# ============================================
# Test av_fetch
# ============================================
subtest 'av_fetch' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_av_fetch')
      ->xs_preamble
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->declare_iv('idx', 'SvIV(ST(1))')
      ->av_fetch('av', 'idx', 'fetched')
      ->if('fetched != NULL')
        ->return_sv('*fetched')
      ->endif
      ->xs_return_undef
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayTest::Fetch',
        cache_dir => $cache_dir,
        functions => {
            'ArrayTest::Fetch::get' => { source => 'test_av_fetch', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $array = [10, 20, 30, 'hello'];
    is(ArrayTest::Fetch::get($array, 0), 10, 'av_fetch index 0');
    is(ArrayTest::Fetch::get($array, 2), 30, 'av_fetch index 2');
    is(ArrayTest::Fetch::get($array, 3), 'hello', 'av_fetch string');
    is(ArrayTest::Fetch::get($array, 10), undef, 'av_fetch out of bounds');
    is(ArrayTest::Fetch::get($array, -1), 'hello', 'av_fetch negative index');
};

# ============================================
# Test av_store
# ============================================
subtest 'av_store' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_av_store')
      ->xs_preamble
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->declare_iv('idx', 'SvIV(ST(1))')
      ->declare_sv('val', 'newSVsv(ST(2))')
      ->av_store('av', 'idx', 'val')
      ->return_yes
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayTest::Store',
        cache_dir => $cache_dir,
        functions => {
            'ArrayTest::Store::set' => { source => 'test_av_store', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $array = [1, 2, 3];
    ok(ArrayTest::Store::set($array, 1, 200), 'av_store returns true');
    is($array->[1], 200, 'av_store modified element');
    
    ArrayTest::Store::set($array, 5, 'extended');
    is($array->[5], 'extended', 'av_store can extend array');
};

# ============================================
# Test av_push
# ============================================
subtest 'av_push' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_av_push')
      ->xs_preamble
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->declare_sv('val', 'newSVsv(ST(1))')
      ->av_push('av', 'val')
      ->return_iv('av_len(av) + 1')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayTest::Push',
        cache_dir => $cache_dir,
        functions => {
            'ArrayTest::Push::push_val' => { source => 'test_av_push', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $array = [];
    is(ArrayTest::Push::push_val($array, 'first'), 1, 'av_push returns new length');
    is($array->[0], 'first', 'av_push added element');
    
    is(ArrayTest::Push::push_val($array, 'second'), 2, 'av_push length 2');
    is(ArrayTest::Push::push_val($array, 'third'), 3, 'av_push length 3');
    is_deeply($array, ['first', 'second', 'third'], 'av_push all elements');
};

# ============================================
# Test av_len
# ============================================
subtest 'av_len' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_av_len')
      ->xs_preamble
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->av_len('av', 'len')
      ->return_iv('len + 1')  # av_len returns highest index, so +1 for count
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayTest::Len',
        cache_dir => $cache_dir,
        functions => {
            'ArrayTest::Len::count' => { source => 'test_av_len', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ArrayTest::Len::count([]), 0, 'av_len empty array');
    is(ArrayTest::Len::count([1]), 1, 'av_len single element');
    is(ArrayTest::Len::count([1, 2, 3, 4, 5]), 5, 'av_len five elements');
};

# ============================================
# Test av_pop (using raw since no direct method)
# ============================================
subtest 'av_pop via raw' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_av_pop')
      ->xs_preamble
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->declare_sv('popped', 'av_pop(av)')
      ->if('popped != NULL')
        ->return_sv('popped')
      ->endif
      ->xs_return_undef
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayTest::Pop',
        cache_dir => $cache_dir,
        functions => {
            'ArrayTest::Pop::pop_val' => { source => 'test_av_pop', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $array = [1, 2, 3];
    is(ArrayTest::Pop::pop_val($array), 3, 'av_pop returns last');
    is_deeply($array, [1, 2], 'av_pop modified array');
    
    is(ArrayTest::Pop::pop_val($array), 2, 'av_pop second');
    is(ArrayTest::Pop::pop_val($array), 1, 'av_pop third');
    is(ArrayTest::Pop::pop_val($array), undef, 'av_pop empty');
};

# ============================================
# Test combined hash operations
# ============================================
subtest 'combined hash operations' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_hash_ops')
      ->xs_preamble
      ->declare_hv('hv', '(HV*)SvRV(ST(0))')
      ->hv_fetch('hv', 'count', 5, 'existing')
      ->declare_iv('count', '0')
      ->if('existing != NULL')
        ->raw('count = SvIV(*existing);')
      ->endif
      ->raw('count++;')
      ->hv_store('hv', 'count', 5, 'newSViv(count)')
      ->return_iv('count')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'HashTest::Counter',
        cache_dir => $cache_dir,
        functions => {
            'HashTest::Counter::increment' => { source => 'test_hash_ops', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $hash = {};
    is(HashTest::Counter::increment($hash), 1, 'First increment');
    is(HashTest::Counter::increment($hash), 2, 'Second increment');
    is(HashTest::Counter::increment($hash), 3, 'Third increment');
    is($hash->{count}, 3, 'Hash contains count');
};

done_testing();
