#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test xs_function
# ============================================
subtest 'xs_function' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('my_func')
      ->xs_preamble
      ->return_iv('42')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::Function',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::Function::answer' => { source => 'my_func', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::Function::answer(), 42, 'xs_function works');
};

# ============================================
# Test xs_preamble
# ============================================
subtest 'xs_preamble with stack access' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_preamble')
      ->xs_preamble  # provides dXSARGS, items, etc.
      ->return_iv('items')  # use items from preamble
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::Preamble',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::Preamble::count_args' => { source => 'test_preamble', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::Preamble::count_args(), 0, 'preamble 0 args');
    is(XSTest::Preamble::count_args(1), 1, 'preamble 1 arg');
    is(XSTest::Preamble::count_args(1, 2, 3), 3, 'preamble 3 args');
};

# ============================================
# Test xs_end proper stack handling
# ============================================
subtest 'xs_end with proper return' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_xs_end')
      ->xs_preamble
      ->declare_iv('a', 'SvIV(ST(0))')
      ->declare_iv('b', 'SvIV(ST(1))')
      ->return_iv('a + b')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::XSEnd',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::XSEnd::add' => { source => 'test_xs_end', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::XSEnd::add(10, 20), 30, 'xs_end proper return');
};

# ============================================
# Test line
# ============================================
subtest 'line' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_line')
      ->xs_preamble
      ->line('IV value = 100;')
      ->line('value = value * 2;')
      ->return_iv('value')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::Line',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::Line::compute' => { source => 'test_line', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::Line::compute(), 200, 'line works');
};

# ============================================
# Test raw
# ============================================
subtest 'raw' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_raw')
      ->xs_preamble
      ->raw('IV x = 5;')
      ->raw('IV y = 10;')
      ->raw('IV z = x * y + 3;')
      ->return_iv('z')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::Raw',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::Raw::compute' => { source => 'test_raw', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::Raw::compute(), 53, 'raw works');
};

# ============================================
# Test comment
# ============================================
subtest 'comment' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_comment')
      ->xs_preamble
      ->comment('This is a test function')
      ->declare_iv('result', '42')
      ->comment('Return the answer')
      ->return_iv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::Comment',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::Comment::answer' => { source => 'test_comment', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::Comment::answer(), 42, 'comment does not affect function');
    like($b->code, qr{/\* This is a test function \*/}, 'comment in code');
};

# ============================================
# Test blank
# ============================================
subtest 'blank' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_blank')
      ->xs_preamble
      ->declare_iv('a', '1')
      ->blank
      ->declare_iv('b', '2')
      ->blank
      ->return_iv('a + b')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::Blank',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::Blank::sum' => { source => 'test_blank', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::Blank::sum(), 3, 'blank does not affect function');
};

# ============================================
# Test indentation
# ============================================
subtest 'indentation' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_indent')
      ->xs_preamble
      ->declare_iv('sum', '0')
      ->for('IV i = 0', 'i < 3', 'i++')
        ->for('IV j = 0', 'j < 3', 'j++')
          ->raw('sum += i * j;')
        ->endfor
      ->endfor
      ->return_iv('sum')
      ->xs_end;
    
    # Verify proper nesting in generated code
    my $code = $b->code;
    like($code, qr/for.*i = 0/, 'outer for present');
    like($code, qr/for.*j = 0/, 'inner for present');
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'XSTest::Indent',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::Indent::nested' => { source => 'test_indent', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    # sum of i*j for i,j in [0,2] = 0+0+0 + 0+1+2 + 0+2+4 = 9
    is(XSTest::Indent::nested(), 9, 'nested loops work');
};

# ============================================
# Test multiple functions in one builder
# ============================================
subtest 'multiple functions' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('func_add')
      ->xs_preamble
      ->return_iv('SvIV(ST(0)) + SvIV(ST(1))')
      ->xs_end;
    
    $b->xs_function('func_sub')
      ->xs_preamble
      ->return_iv('SvIV(ST(0)) - SvIV(ST(1))')
      ->xs_end;
    
    $b->xs_function('func_mul')
      ->xs_preamble
      ->return_iv('SvIV(ST(0)) * SvIV(ST(1))')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::Multi',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::Multi::add' => { source => 'func_add', is_xs_native => 1 },
            'XSTest::Multi::sub' => { source => 'func_sub', is_xs_native => 1 },
            'XSTest::Multi::mul' => { source => 'func_mul', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::Multi::add(10, 3), 13, 'multi add');
    is(XSTest::Multi::sub(10, 3), 7, 'multi sub');
    is(XSTest::Multi::mul(10, 3), 30, 'multi mul');
};

# ============================================
# Test return_undef via xs_return_undef
# ============================================
subtest 'xs_return_undef' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('test_xs_return_undef')
      ->xs_preamble
      ->if('items == 0')
        ->xs_return_undef
      ->endif
      ->return_sv('ST(0)')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'XSTest::ReturnUndef',
        cache_dir => $cache_dir,
        functions => {
            'XSTest::ReturnUndef::maybe' => { source => 'test_xs_return_undef', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(XSTest::ReturnUndef::maybe(), undef, 'xs_return_undef returns undef');
    is(XSTest::ReturnUndef::maybe('hello'), 'hello', 'xs_return_undef fallthrough');
};

done_testing();
