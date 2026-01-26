#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Complex class implementation
# ============================================
subtest 'complete class implementation' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Constructor
    $b->xs_function('point_new')
      ->xs_preamble
      ->raw('SV* class_sv = ST(0);')
      ->raw('STRLEN class_len;')
      ->raw('const char* class = SvPV(class_sv, class_len);')
      ->new_hv('hv')
      ->if('items >= 2')
        ->hv_store('hv', 'x', 1, 'newSVnv(SvNV(ST(1)))')
      ->else
        ->hv_store('hv', 'x', 1, 'newSVnv(0)')
      ->endif
      ->if('items >= 3')
        ->hv_store('hv', 'y', 1, 'newSVnv(SvNV(ST(2)))')
      ->else
        ->hv_store('hv', 'y', 1, 'newSVnv(0)')
      ->endif
      ->declare_sv('ref', 'newRV_noinc((SV*)hv)')
      ->raw('sv_bless(ref, gv_stashpvn(class, class_len, GV_ADD));')
      ->return_sv('ref')
      ->xs_end;
    
    # Accessors
    $b->accessor('x', { readonly => 0 })
      ->accessor('y', { readonly => 0 });
    
    # Distance method
    $b->xs_function('point_distance')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'x', 1, 'x_ptr')
      ->hv_fetch('hv', 'y', 1, 'y_ptr')
      ->declare_nv('x', 'x_ptr ? SvNV(*x_ptr) : 0')
      ->declare_nv('y', 'y_ptr ? SvNV(*y_ptr) : 0')
      ->declare_nv('dist', 'sqrt(x*x + y*y)')
      ->return_nv('dist')
      ->xs_end;
    
    # Add method (returns new point)
    $b->xs_function('point_add')
      ->xs_preamble
      ->get_self_hv
      ->raw('HV* other = (HV*)SvRV(ST(1));')
      ->hv_fetch('hv', 'x', 1, 'x1_ptr')
      ->hv_fetch('hv', 'y', 1, 'y1_ptr')
      ->hv_fetch('other', 'x', 1, 'x2_ptr')
      ->hv_fetch('other', 'y', 1, 'y2_ptr')
      ->declare_nv('x1', 'x1_ptr ? SvNV(*x1_ptr) : 0')
      ->declare_nv('y1', 'y1_ptr ? SvNV(*y1_ptr) : 0')
      ->declare_nv('x2', 'x2_ptr ? SvNV(*x2_ptr) : 0')
      ->declare_nv('y2', 'y2_ptr ? SvNV(*y2_ptr) : 0')
      ->new_hv('result_hv')
      ->hv_store('result_hv', 'x', 1, 'newSVnv(x1 + x2)')
      ->hv_store('result_hv', 'y', 1, 'newSVnv(y1 + y2)')
      ->declare_sv('result', 'newRV_noinc((SV*)result_hv)')
      ->raw('sv_bless(result, SvSTASH(SvRV(self)));')
      ->return_sv('result')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => "#include <math.h>\n" . $b->code,
        name      => 'ComplexTest::Point',
        cache_dir => $cache_dir,
        functions => {
            'ComplexTest::Point::new'      => { source => 'point_new', is_xs_native => 1 },
            'ComplexTest::Point::x'        => { source => 'x', is_xs_native => 1 },
            'ComplexTest::Point::y'        => { source => 'y', is_xs_native => 1 },
            'ComplexTest::Point::distance' => { source => 'point_distance', is_xs_native => 1 },
            'ComplexTest::Point::add'      => { source => 'point_add', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    # Test constructor
    my $p1 = ComplexTest::Point->new(3, 4);
    isa_ok($p1, 'ComplexTest::Point');
    is($p1->x, 3, 'x accessor');
    is($p1->y, 4, 'y accessor');
    
    # Test distance (3-4-5 triangle)
    is($p1->distance, 5, 'distance correct');
    
    # Test add
    my $p2 = ComplexTest::Point->new(1, 2);
    my $p3 = $p1->add($p2);
    is($p3->x, 4, 'add x');
    is($p3->y, 6, 'add y');
    isa_ok($p3, 'ComplexTest::Point');
};

# ============================================
# Stack-based calculator
# ============================================
subtest 'stack calculator' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Constructor
    $b->xs_function('calc_new')
      ->xs_preamble
      ->raw('SV* class_sv = ST(0);')
      ->raw('STRLEN class_len;')
      ->raw('const char* class = SvPV(class_sv, class_len);')
      ->new_hv('hv')
      ->new_av('stack')
      ->hv_store('hv', 'stack', 5, 'newRV_noinc((SV*)stack)')
      ->declare_sv('ref', 'newRV_noinc((SV*)hv)')
      ->raw('sv_bless(ref, gv_stashpvn(class, class_len, GV_ADD));')
      ->return_sv('ref')
      ->xs_end;
    
    # Push value
    $b->xs_function('calc_push')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'stack', 5, 'stack_ref')
      ->raw('AV* stack = (AV*)SvRV(*stack_ref);')
      ->av_push('stack', 'newSVnv(SvNV(ST(1)))')
      ->return_self
      ->xs_end;
    
    # Pop value
    $b->xs_function('calc_pop')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'stack', 5, 'stack_ref')
      ->raw('AV* stack = (AV*)SvRV(*stack_ref);')
      ->raw('SV* val = av_pop(stack);')
      ->if('val != NULL')
        ->return_nv('SvNV(val)')
      ->endif
      ->return_undef
      ->xs_end;
    
    # Add top two
    $b->xs_function('calc_add')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'stack', 5, 'stack_ref')
      ->raw('AV* stack = (AV*)SvRV(*stack_ref);')
      ->raw('SV* b = av_pop(stack);')
      ->raw('SV* a = av_pop(stack);')
      ->if('a && b')
        ->av_push('stack', 'newSVnv(SvNV(a) + SvNV(b))')
      ->endif
      ->return_self
      ->xs_end;
    
    # Multiply top two
    $b->xs_function('calc_mul')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'stack', 5, 'stack_ref')
      ->raw('AV* stack = (AV*)SvRV(*stack_ref);')
      ->raw('SV* b = av_pop(stack);')
      ->raw('SV* a = av_pop(stack);')
      ->if('a && b')
        ->av_push('stack', 'newSVnv(SvNV(a) * SvNV(b))')
      ->endif
      ->return_self
      ->xs_end;
    
    # Peek at top
    $b->xs_function('calc_peek')
      ->xs_preamble
      ->get_self_hv
      ->hv_fetch('hv', 'stack', 5, 'stack_ref')
      ->raw('AV* stack = (AV*)SvRV(*stack_ref);')
      ->av_len('stack', 'len')
      ->if('len >= 0')
        ->av_fetch('stack', 'len', 'top')
        ->if('top')
          ->return_nv('SvNV(*top)')
        ->endif
      ->endif
      ->return_undef
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ComplexTest::Calc',
        cache_dir => $cache_dir,
        functions => {
            'ComplexTest::Calc::new'  => { source => 'calc_new', is_xs_native => 1 },
            'ComplexTest::Calc::push' => { source => 'calc_push', is_xs_native => 1 },
            'ComplexTest::Calc::pop'  => { source => 'calc_pop', is_xs_native => 1 },
            'ComplexTest::Calc::add'  => { source => 'calc_add', is_xs_native => 1 },
            'ComplexTest::Calc::mul'  => { source => 'calc_mul', is_xs_native => 1 },
            'ComplexTest::Calc::peek' => { source => 'calc_peek', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $calc = ComplexTest::Calc->new;
    isa_ok($calc, 'ComplexTest::Calc');
    
    # Test chained operations: (3 + 4) * 2 = 14
    $calc->push(3)->push(4)->add->push(2)->mul;
    is($calc->peek, 14, 'calculator result');
    is($calc->pop, 14, 'pop result');
    ok(!defined($calc->peek), 'empty stack');
};

# ============================================
# Linked list node (with references)
# ============================================
subtest 'linked list node' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Constructor
    $b->xs_function('node_new')
      ->xs_preamble
      ->raw('SV* class_sv = ST(0);')
      ->raw('STRLEN class_len;')
      ->raw('const char* class = SvPV(class_sv, class_len);')
      ->new_hv('hv')
      ->if('items >= 2')
        ->hv_store('hv', 'value', 5, 'newSVsv(ST(1))')
      ->endif
      ->declare_sv('ref', 'newRV_noinc((SV*)hv)')
      ->raw('sv_bless(ref, gv_stashpvn(class, class_len, GV_ADD));')
      ->return_sv('ref')
      ->xs_end;
    
    # Value accessor
    $b->accessor('value', { readonly => 0 });
    
    # Next accessor
    $b->accessor('next', { readonly => 0 });
    
    # Traverse - count nodes
    $b->xs_function('node_count')
      ->xs_preamble
      ->get_self
      ->declare_iv('count', '0')
      ->declare_sv('current', 'self')
      ->while('SvOK(current) && SvROK(current)')
        ->raw('count++;')
        ->raw('HV* hv = (HV*)SvRV(current);')
        ->raw('SV** next_ptr = hv_fetch(hv, "next", 4, 0);')
        ->if('next_ptr && *next_ptr && SvOK(*next_ptr)')
          ->raw('current = *next_ptr;')
        ->else
          ->raw('break;')
        ->endif
      ->endwhile
      ->return_iv('count')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ComplexTest::Node',
        cache_dir => $cache_dir,
        functions => {
            'ComplexTest::Node::new'   => { source => 'node_new', is_xs_native => 1 },
            'ComplexTest::Node::value' => { source => 'value', is_xs_native => 1 },
            'ComplexTest::Node::next'  => { source => 'next', is_xs_native => 1 },
            'ComplexTest::Node::count' => { source => 'node_count', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $n1 = ComplexTest::Node->new('first');
    my $n2 = ComplexTest::Node->new('second');
    my $n3 = ComplexTest::Node->new('third');
    
    is($n1->value, 'first', 'node value');
    
    $n1->next($n2);
    $n2->next($n3);
    
    is($n1->count, 3, 'linked list count');
    is($n2->count, 2, 'from second node');
    is($n3->count, 1, 'single node');
};

# ============================================
# Fibonacci with memoization
# ============================================
subtest 'fibonacci with cache' => sub {
    my $b = XS::JIT::Builder->new;
    
    # We'll create a simple iterative version for now
    $b->xs_function('fib')
      ->xs_preamble
      ->declare_iv('n', 'SvIV(ST(0))')
      ->if('n <= 0')
        ->return_iv('0')
      ->endif
      ->if('n == 1')
        ->return_iv('1')
      ->endif
      ->declare_iv('a', '0')
      ->declare_iv('b', '1')
      ->declare_iv('temp', '0')
      ->for('IV i = 2', 'i <= n', 'i++')
        ->raw('temp = a + b;')
        ->raw('a = b;')
        ->raw('b = temp;')
      ->endfor
      ->return_iv('b')
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'ComplexTest::Fib',
        cache_dir => $cache_dir,
        functions => {
            'ComplexTest::Fib::calculate' => { source => 'fib', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(ComplexTest::Fib::calculate(0), 0, 'fib(0)');
    is(ComplexTest::Fib::calculate(1), 1, 'fib(1)');
    is(ComplexTest::Fib::calculate(2), 1, 'fib(2)');
    is(ComplexTest::Fib::calculate(10), 55, 'fib(10)');
    is(ComplexTest::Fib::calculate(20), 6765, 'fib(20)');
};

done_testing();
