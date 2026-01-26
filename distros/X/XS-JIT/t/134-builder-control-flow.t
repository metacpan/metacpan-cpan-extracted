#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder qw(:types);

# Phase 5 tests: Control Flow & Extended Patterns
# Tests for do/end_do_while, context helpers, return_list, ternary, delegate_method

my $cache_dir = tempdir(CLEANUP => 1);

# Test 1-2: do/end_do_while generates correct code
subtest 'do/end_do_while code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('test_do_while')
      ->xs_preamble
      ->declare('int', 'i', '0')
      ->do_loop
        ->line('i++;')
      ->end_do_while('i < 5')
      ->line('XSRETURN_EMPTY;')
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/do\s*\{/, 
        'generates do {');
    like($code, qr/\}\s*while\s*\(\s*i\s*<\s*5\s*\)\s*;/, 
        'generates } while (i < 5);');
};

# Test 3-4: if_list_context/if_scalar_context generate correct code
subtest 'context helpers code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('test_context')
      ->xs_preamble
      ->if_list_context
        ->line('/* list */')
      ->else
        ->line('/* scalar */')
      ->endif
      ->line('XSRETURN_EMPTY;')
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/GIMME_V\s*==\s*G_LIST/, 
        'generates GIMME_V == G_LIST');
};

subtest 'if_scalar_context code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('test_scalar')
      ->xs_preamble
      ->if_scalar_context
        ->line('/* scalar */')
      ->endif
      ->line('XSRETURN_EMPTY;')
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/GIMME_V\s*==\s*G_SCALAR/, 
        'generates GIMME_V == G_SCALAR');
};

# Test 5-6: extend_stack and return_list generate correct code
subtest 'extend_stack code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('test_extend')
      ->xs_preamble
      ->extend_stack('10')
      ->line('XSRETURN(10);')
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/EXTEND\s*\(\s*SP\s*,\s*10\s*\)/, 
        'generates EXTEND(SP, 10)');
};

subtest 'return_list code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('test_return_list')
      ->xs_preamble
      ->return_list(['newSViv(1)', 'newSViv(2)', 'newSViv(3)'])
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/EXTEND\s*\(\s*SP\s*,\s*3\s*\)/, 
        'extends stack for 3 values');
    like($code, qr/ST\(0\)\s*=\s*sv_2mortal/, 
        'mortifies return values');
    like($code, qr/XSRETURN\(3\)/, 
        'returns 3 values');
};

# Test 7-8: declare_ternary generates correct code
subtest 'declare_ternary code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('test_ternary')
      ->xs_preamble
      ->declare_ternary('SV*', 'val', 'items > 1', 'ST(1)', '&PL_sv_undef')
      ->line('ST(0) = val;')
      ->line('XSRETURN(1);')
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/SV\*\s+val\s*=\s*\(items\s*>\s*1\)\s*\?\s*ST\(1\)\s*:\s*&PL_sv_undef/, 
        'generates ternary declaration');
};

# Test 9-10: assign_ternary generates correct code
subtest 'assign_ternary code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('test_assign_ternary')
      ->xs_preamble
      ->declare('SV*', 'result', 'NULL')
      ->assign_ternary('result', 'found', '*svp', '&PL_sv_undef')
      ->line('ST(0) = result;')
      ->line('XSRETURN(1);')
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/result\s*=\s*\(found\)\s*\?\s*\*svp\s*:\s*&PL_sv_undef/, 
        'generates ternary assignment');
};

# Test 11-14: delegate_method generates correct code
subtest 'delegate_method code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->delegate_method('dm_get_name', 'delegate', 8, 'name');
    
    my $code = $b->code;
    
    like($code, qr/hv_fetch\s*\(\s*hv\s*,\s*"delegate"/, 
        'fetches delegate attribute');
    like($code, qr/call_method\s*\(\s*"name"/, 
        'calls target method');
    like($code, qr/G_SCALAR/, 
        'calls in scalar context');
    like($code, qr/Cannot delegate/, 
        'croaks if delegate not set');
};

# Test 15-16: Integration test for delegate_method
subtest 'delegate_method integration' => sub {
    # Create a delegate class in Perl
    {
        package DelegateTarget;
        sub new { bless { value => $_[1] }, $_[0] }
        sub get_value { $_[0]->{value} }
        sub set_value { $_[0]->{value} = $_[1]; return $_[0] }
        sub add { $_[0]->{value} + $_[1] }
    }
    
    my $b = XS::JIT::Builder->new;
    $b->new_simple('dw_new')
      ->rw_accessor('dw_delegate', 'delegate', 8)
      ->delegate_method('dw_get_value', 'delegate', 8, 'get_value')
      ->delegate_method('dw_add', 'delegate', 8, 'add');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'DelegateWrapper',
        cache_dir => $cache_dir,
        functions => {
            'DelegateWrapper::new'       => { source => 'dw_new', is_xs_native => 1 },
            'DelegateWrapper::delegate'  => { source => 'dw_delegate', is_xs_native => 1 },
            'DelegateWrapper::get_value' => { source => 'dw_get_value', is_xs_native => 1 },
            'DelegateWrapper::add'       => { source => 'dw_add', is_xs_native => 1 },
        },
    );
    
    my $target = DelegateTarget->new(42);
    my $wrapper = DelegateWrapper->new();
    $wrapper->delegate($target);
    
    is($wrapper->get_value, 42, 'delegation returns correct value');
    is($wrapper->add(8), 50, 'delegation with args works');
};

done_testing;
