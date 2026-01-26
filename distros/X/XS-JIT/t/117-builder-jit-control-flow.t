#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test if/endif
# ============================================
subtest 'if/endif' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_if')
      ->xs_preamble
      ->declare_iv('val', 'SvIV(ST(0))')
      ->if('val > 0')
        ->return_pv('"positive"')
      ->endif
      ->return_pv('"not positive"')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::If',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::If::check' => { source => 'test_if', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::If::check(5), 'positive', 'if true branch');
    is(ControlTest::If::check(0), 'not positive', 'if false fallthrough');
    is(ControlTest::If::check(-3), 'not positive', 'if negative fallthrough');
};

# ============================================
# Test if/else/endif
# ============================================
subtest 'if/else/endif' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_if_else')
      ->xs_preamble
      ->declare_iv('val', 'SvIV(ST(0))')
      ->if('val % 2 == 0')
        ->return_pv('"even"')
      ->else
        ->return_pv('"odd"')
      ->endif
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::IfElse',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::IfElse::parity' => { source => 'test_if_else', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::IfElse::parity(4), 'even', 'if/else even');
    is(ControlTest::IfElse::parity(7), 'odd', 'if/else odd');
    is(ControlTest::IfElse::parity(0), 'even', 'if/else zero');
};

# ============================================
# Test if/elsif/else/endif
# ============================================
subtest 'if/elsif/else/endif' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_elsif')
      ->xs_preamble
      ->declare_iv('val', 'SvIV(ST(0))')
      ->if('val > 0')
        ->return_pv('"positive"')
      ->elsif('val < 0')
        ->return_pv('"negative"')
      ->else
        ->return_pv('"zero"')
      ->endif
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::Elsif',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::Elsif::sign' => { source => 'test_elsif', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::Elsif::sign(5), 'positive', 'elsif positive');
    is(ControlTest::Elsif::sign(-3), 'negative', 'elsif negative');
    is(ControlTest::Elsif::sign(0), 'zero', 'elsif zero');
};

# ============================================
# Test nested if
# ============================================
subtest 'nested if' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_nested_if')
      ->xs_preamble
      ->declare_iv('a', 'SvIV(ST(0))')
      ->declare_iv('b', 'SvIV(ST(1))')
      ->if('a > 0')
        ->if('b > 0')
          ->return_pv('"both positive"')
        ->else
          ->return_pv('"a positive only"')
        ->endif
      ->else
        ->if('b > 0')
          ->return_pv('"b positive only"')
        ->else
          ->return_pv('"neither positive"')
        ->endif
      ->endif
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::Nested',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::Nested::classify' => { source => 'test_nested_if', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::Nested::classify(1, 1), 'both positive', 'nested both');
    is(ControlTest::Nested::classify(1, -1), 'a positive only', 'nested a only');
    is(ControlTest::Nested::classify(-1, 1), 'b positive only', 'nested b only');
    is(ControlTest::Nested::classify(-1, -1), 'neither positive', 'nested neither');
};

# ============================================
# Test for loop
# ============================================
subtest 'for loop' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_for')
      ->xs_preamble
      ->declare_iv('n', 'SvIV(ST(0))')
      ->declare_iv('sum', '0')
      ->for('IV i = 1', 'i <= n', 'i++')
        ->raw('sum += i;')
      ->endfor
      ->return_iv('sum')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::For',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::For::sum_to' => { source => 'test_for', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::For::sum_to(5), 15, 'for loop sum to 5');
    is(ControlTest::For::sum_to(10), 55, 'for loop sum to 10');
    is(ControlTest::For::sum_to(0), 0, 'for loop sum to 0');
    is(ControlTest::For::sum_to(1), 1, 'for loop sum to 1');
};

# ============================================
# Test while loop
# ============================================
subtest 'while loop' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_while')
      ->xs_preamble
      ->declare_iv('n', 'SvIV(ST(0))')
      ->declare_iv('count', '0')
      ->while('n > 0')
        ->raw('n = n / 2;')
        ->raw('count++;')
      ->endwhile
      ->return_iv('count')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::While',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::While::log2_steps' => { source => 'test_while', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::While::log2_steps(1), 1, 'while 1 step');
    is(ControlTest::While::log2_steps(4), 3, 'while 4->2->1->0');
    is(ControlTest::While::log2_steps(16), 5, 'while 16 steps');
    is(ControlTest::While::log2_steps(0), 0, 'while 0 steps');
};

# ============================================
# Test block/endblock
# ============================================
subtest 'block/endblock' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_block')
      ->xs_preamble
      ->declare_iv('result', '0')
      ->block
        ->declare_iv('temp', 'SvIV(ST(0))')
        ->raw('temp = temp * 2;')
        ->raw('result = temp + 1;')
      ->endblock
      ->return_iv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::Block',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::Block::compute' => { source => 'test_block', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::Block::compute(5), 11, 'block scoping 5*2+1');
    is(ControlTest::Block::compute(10), 21, 'block scoping 10*2+1');
};

# ============================================
# Test multiple elsif
# ============================================
subtest 'multiple elsif' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_multi_elsif')
      ->xs_preamble
      ->declare_iv('val', 'SvIV(ST(0))')
      ->if('val == 1')
        ->return_pv('"one"')
      ->elsif('val == 2')
        ->return_pv('"two"')
      ->elsif('val == 3')
        ->return_pv('"three"')
      ->elsif('val == 4')
        ->return_pv('"four"')
      ->else
        ->return_pv('"other"')
      ->endif
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::MultiElsif',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::MultiElsif::name' => { source => 'test_multi_elsif', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::MultiElsif::name(1), 'one', 'multi elsif 1');
    is(ControlTest::MultiElsif::name(2), 'two', 'multi elsif 2');
    is(ControlTest::MultiElsif::name(3), 'three', 'multi elsif 3');
    is(ControlTest::MultiElsif::name(4), 'four', 'multi elsif 4');
    is(ControlTest::MultiElsif::name(5), 'other', 'multi elsif other');
};

# ============================================
# Test for with array iteration
# ============================================
subtest 'for with array iteration' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_for_array')
      ->xs_preamble
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->declare_iv('len', 'av_len(av) + 1')
      ->declare_iv('sum', '0')
      ->for('IV i = 0', 'i < len', 'i++')
        ->av_fetch('av', 'i', 'elem')
        ->if('elem != NULL')
          ->raw('sum += SvIV(*elem);')
        ->endif
      ->endfor
      ->return_iv('sum')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ControlTest::ForArray',
        cache_dir => $cache_dir,
        functions => {
            'ControlTest::ForArray::sum' => { source => 'test_for_array', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ControlTest::ForArray::sum([1, 2, 3, 4, 5]), 15, 'for array sum');
    is(ControlTest::ForArray::sum([10, 20, 30]), 60, 'for array sum 2');
    is(ControlTest::ForArray::sum([]), 0, 'for empty array');
};

done_testing();
