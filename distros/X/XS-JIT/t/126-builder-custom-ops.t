#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# Test the custom op builder methods generate correct code
# Note: The C implementation adds prefixes like S_pp_, S_ck_ for static functions

my $b;

# ============================================
# PP Function Builders
# ============================================

subtest 'pp_start' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('my_getter');
    my $code = $b->code;
    # Implementation adds S_pp_ prefix
    like($code, qr/static\s+OP\s*\*\s*S_pp_my_getter\s*\(pTHX\)/, 'pp_start generates static OP* function');
    like($code, qr/\{/, 'pp_start opens brace');
};

subtest 'pp_end' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test_pp')->pp_dsp->pp_return->pp_end;  # pp_return adds return NORMAL
    my $code = $b->code;
    like($code, qr/return\s+NORMAL/, 'pp_return adds return NORMAL');
    like($code, qr/\}\s*$/, 'pp_end closes brace');
};

subtest 'pp_dsp' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp;
    like($b->code, qr/dSP;/, 'pp_dsp adds dSP declaration');
};

subtest 'pp_get_self' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_get_self;
    like($b->code, qr/SV\s*\*\s*self\s*=\s*TOPs/, 'pp_get_self uses TOPs');
};

subtest 'pp_pop_self' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_pop_self;
    like($b->code, qr/SV\s*\*\s*self\s*=\s*POPs/, 'pp_pop_self uses POPs');
};

subtest 'pp_pop_sv' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_pop_sv('value');
    like($b->code, qr/SV\s*\*\s*value\s*=\s*POPs/, 'pp_pop_sv declares and pops SV');
};

subtest 'pp_pop_nv' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_pop_nv('amount');
    like($b->code, qr/NV\s+amount\s*=\s*POPn/, 'pp_pop_nv declares and pops NV');
};

subtest 'pp_pop_iv' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_pop_iv('count');
    like($b->code, qr/IV\s+count\s*=\s*POPi/, 'pp_pop_iv declares and pops IV');
};

subtest 'pp_get_slots' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_get_self->pp_get_slots;
    # Implementation uses AvARRAY optimization
    like($b->code, qr/AvARRAY\(\(AV\s*\*\)\s*SvRV\(self\)\)/, 'pp_get_slots extracts array from self');
};

subtest 'pp_slot' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_get_self->pp_get_slots->pp_slot('val', 0);
    # Implementation uses direct array access with null check
    like($b->code, qr/SV\s*\*\s*val\s*=\s*ary\[0\]/, 'pp_slot accesses array element');
};

subtest 'pp_return_sv' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_return_sv('result');
    like($b->code, qr/SETs\(result\)/, 'pp_return_sv uses SETs');
    like($b->code, qr/return\s+NORMAL/, 'pp_return_sv returns NORMAL');
};

subtest 'pp_return_nv' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_return_nv('value');
    # Implementation uses newSVnv wrapper
    like($b->code, qr/sv_2mortal\(newSVnv\(value\)\)/, 'pp_return_nv creates mortal NV');
};

subtest 'pp_return_iv' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_return_iv('count');
    # Implementation uses newSViv wrapper
    like($b->code, qr/sv_2mortal\(newSViv\(count\)\)/, 'pp_return_iv creates mortal IV');
};

subtest 'pp_return_pv' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_dsp->pp_return_pv('str');
    like($b->code, qr/sv_2mortal\(newSVpv\(str/, 'pp_return_pv creates mortal SV from string');
};

subtest 'pp_return' => sub {
    $b = XS::JIT::Builder->new;
    $b->pp_start('test')->pp_return;
    like($b->code, qr/return\s+NORMAL/, 'pp_return returns NORMAL');
};

# ============================================
# Call Checker Builders
# ============================================

subtest 'ck_start' => sub {
    $b = XS::JIT::Builder->new;
    $b->ck_start('my_method');
    my $code = $b->code;
    # Implementation adds S_ck_ prefix
    like($code, qr/static\s+OP\s*\*\s*S_ck_my_method/, 'ck_start generates static OP* function');
    like($code, qr/OP\s*\*\s*entersubop/, 'ck_start has entersubop param');
    like($code, qr/GV\s*\*\s*namegv/, 'ck_start has namegv param');
    like($code, qr/SV\s*\*\s*ckobj/, 'ck_start has ckobj param');
};

subtest 'ck_end' => sub {
    $b = XS::JIT::Builder->new;
    $b->ck_start('test_ck')->ck_preamble->ck_end;  # need preamble for proper fallback
    my $code = $b->code;
    # ck_end without build_unop/binop falls back
    like($code, qr/\}\s*$/, 'ck_end closes brace');
};

subtest 'ck_preamble' => sub {
    $b = XS::JIT::Builder->new;
    $b->ck_start('test_ck')->ck_preamble;
    my $code = $b->code;
    like($code, qr/OP\s*\*\s*pushmark/, 'ck_preamble declares pushmark');
    like($code, qr/OP\s*\*\s*selfop/, 'ck_preamble declares selfop');
    like($code, qr/cUNOPx/, 'ck_preamble extracts ops');
};

subtest 'ck_build_unop' => sub {
    $b = XS::JIT::Builder->new;
    $b->ck_start('test_ck')->ck_preamble->ck_build_unop('pp_getter', 'slot_idx');
    my $code = $b->code;
    like($code, qr/OP_CUSTOM/, 'ck_build_unop uses OP_CUSTOM');
    like($code, qr/UNOP\s*\*\s*newop/, 'ck_build_unop creates UNOP');
    like($code, qr/op_targ\s*=.*slot_idx/, 'ck_build_unop sets op_targ');
    like($code, qr/pp_getter/, 'ck_build_unop references pp function');
};

subtest 'ck_build_binop' => sub {
    $b = XS::JIT::Builder->new;
    $b->ck_start('test_ck')->ck_preamble->ck_build_binop('pp_setter', 'slot_idx');
    my $code = $b->code;
    like($code, qr/OP_CUSTOM/, 'ck_build_binop uses OP_CUSTOM');
    like($code, qr/BINOP\s*\*\s*newop/, 'ck_build_binop creates BINOP');
    like($code, qr/op_targ\s*=.*slot_idx/, 'ck_build_binop sets op_targ');
};

subtest 'ck_fallback' => sub {
    $b = XS::JIT::Builder->new;
    $b->ck_start('test_ck')->ck_fallback;
    # fallback returns entersubop directly
    like($b->code, qr/return\s+entersubop/, 'ck_fallback returns entersubop');
};

# ============================================
# XOP Helpers
# ============================================

subtest 'xop_declare' => sub {
    $b = XS::JIT::Builder->new;
    $b->xop_declare('getter_xop', 'pp_getter', 'slot getter op');
    my $code = $b->code;
    # XOP name has xop_ prefix in the variable name
    like($code, qr/static\s+XOP\s+xop_getter_xop/, 'xop_declare declares static XOP');
    like($code, qr/XopENTRY_set/, 'xop_declare sets XOP entries');
    like($code, qr/xop_name/, 'xop_declare sets xop_name');
    like($code, qr/xop_desc/, 'xop_declare sets xop_desc');
    like($code, qr/Perl_custom_op_register/, 'xop_declare registers the op');
    like($code, qr/pp_getter/, 'xop_declare references pp function');
};

subtest 'register_checker' => sub {
    $b = XS::JIT::Builder->new;
    $b->register_checker('cv', 'ck_my_method', 'newSViv(slot)');
    my $code = $b->code;
    like($code, qr/cv_set_call_checker/, 'register_checker uses cv_set_call_checker');
    like($code, qr/cv/, 'register_checker has cv expression');
    like($code, qr/ck_my_method/, 'register_checker has checker function');
    like($code, qr/newSViv\(slot\)/, 'register_checker has ckobj expression');
};

# ============================================
# Method chaining
# ============================================

subtest 'method chaining' => sub {
    $b = XS::JIT::Builder->new;
    
    # All methods should return $self for chaining
    is($b->pp_start('test'), $b, 'pp_start returns $self');
    is($b->pp_dsp, $b, 'pp_dsp returns $self');
    is($b->pp_get_self, $b, 'pp_get_self returns $self');
    is($b->pp_get_slots, $b, 'pp_get_slots returns $self');
    is($b->pp_slot('x', 0), $b, 'pp_slot returns $self');
    is($b->pp_return_sv('x'), $b, 'pp_return_sv returns $self');
    is($b->pp_end, $b, 'pp_end returns $self');
    
    $b->reset;
    is($b->ck_start('test'), $b, 'ck_start returns $self');
    is($b->ck_preamble, $b, 'ck_preamble returns $self');
    is($b->ck_fallback, $b, 'ck_fallback returns $self');
    is($b->ck_end, $b, 'ck_end returns $self');
    
    $b->reset;
    is($b->xop_declare('xop', 'pp', 'desc'), $b, 'xop_declare returns $self');
    is($b->register_checker('cv', 'ck', 'obj'), $b, 'register_checker returns $self');
};

# ============================================
# Complete example: slot getter op
# ============================================

subtest 'complete slot getter op' => sub {
    $b = XS::JIT::Builder->new;
    
    # Declare XOP
    $b->xop_declare('slot_getter_xop', 'pp_slot_getter', 'slot getter');
    
    # Build pp function - note: pp_slot needs a numeric slot index
    $b->pp_start('pp_slot_getter')
      ->pp_dsp
      ->pp_get_self
      ->pp_get_slots
      ->line('IV slot = PL_op->op_targ;')
      ->line('SV* val = ary[slot] ? ary[slot] : &PL_sv_undef;')
      ->pp_return_sv('val')
      ->pp_end;
    
    my $code = $b->code;
    
    # Verify XOP
    like($code, qr/static\s+XOP\s+xop_slot_getter_xop/, 'has XOP declaration');
    
    # Verify pp function (has S_pp_ prefix)
    like($code, qr/S_pp_pp_slot_getter/, 'has pp function');
    like($code, qr/dSP/, 'has dSP');
    like($code, qr/SV\s*\*\s*self\s*=\s*TOPs/, 'gets self');
    like($code, qr/AvARRAY/, 'gets slots array');
    like($code, qr/PL_op->op_targ/, 'accesses op_targ');
    like($code, qr/SETs\(val\)/, 'sets return value');
    like($code, qr/return\s+NORMAL/, 'returns NORMAL');
};

# ============================================
# Complete example: slot setter op
# ============================================

subtest 'complete slot setter op' => sub {
    $b = XS::JIT::Builder->new;
    
    # Declare XOP
    $b->xop_declare('slot_setter_xop', 'pp_slot_setter', 'slot setter');
    
    # Build pp function for setter
    $b->pp_start('pp_slot_setter')
      ->pp_dsp
      ->pp_pop_sv('value')
      ->pp_pop_self
      ->pp_get_slots
      ->line('IV slot = PL_op->op_targ;')
      ->line('av_store((AV*)SvRV(self), slot, SvREFCNT_inc(value));')
      ->line('PUSHs(value);')
      ->line('PUTBACK;')
      ->pp_return
      ->pp_end;
    
    my $code = $b->code;
    
    # Verify pp function
    like($code, qr/S_pp_pp_slot_setter/, 'has pp function');
    like($code, qr/SV\s*\*\s*value\s*=\s*POPs/, 'pops value');
    like($code, qr/SV\s*\*\s*self\s*=\s*POPs/, 'pops self');
    like($code, qr/av_store/, 'stores to slot');
    like($code, qr/PUSHs\(value\)/, 'pushes return value');
};

# ============================================
# Complete example: call checker
# ============================================

subtest 'complete call checker' => sub {
    $b = XS::JIT::Builder->new;
    
    # Build call checker
    $b->ck_start('slot_getter')
      ->ck_preamble
      ->line('IV slot = SvIV(ckobj);')
      ->ck_build_unop('pp_slot_getter', 'slot')
      ->ck_end;
    
    my $code = $b->code;
    
    # Verify call checker (has S_ck_ prefix)
    like($code, qr/S_ck_slot_getter.*entersubop.*namegv.*ckobj/s, 'has call checker signature');
    like($code, qr/SvIV\(ckobj\)/, 'extracts slot from ckobj');
    like($code, qr/UNOP\s*\*\s*newop/, 'builds UNOP');
    like($code, qr/op_targ\s*=.*slot/, 'sets op_targ to slot');
};

# ============================================
# JIT Compilation test for complete custom op
# ============================================

subtest 'JIT compile pp function' => sub {
    # Build a complete pp function that doubles a slot value
    my $b = XS::JIT::Builder->new;
    
    # Create a pp function
    $b->pp_start('pp_double_slot')
      ->pp_dsp
      ->pp_get_self
      ->pp_get_slots
      ->line('IV slot = PL_op->op_targ;')
      ->line('SV* val = ary[slot] ? ary[slot] : &PL_sv_undef;')
      ->line('IV doubled = SvIV(val) * 2;')
      ->pp_return_iv('doubled')
      ->pp_end;
    
    # Also add a normal XS function that we can compile and test
    $b->xs_function('get_doubled')
      ->xs_preamble
      ->check_items(2, 2, '$self, $slot')
      ->get_self
      ->line('AV* av = (AV*)SvRV(self);')
      ->line('IV slot = SvIV(ST(1));')
      ->line('SV** elem = av_fetch(av, slot, 0);')
      ->if('elem && *elem')
        ->line('IV doubled = SvIV(*elem) * 2;')
        ->return_iv('doubled')
      ->endif
      ->return_undef
      ->xs_end;
    
    my $code = $b->code;
    
    # Verify pp function was generated
    like($code, qr/S_pp_pp_double_slot/, 'pp function generated');
    like($code, qr/PL_op->op_targ/, 'uses op_targ');
    
    # Compile with XS::JIT
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'CustomOpTest::Double',
        cache_dir => $cache_dir,
        functions => {
            'CustomOpTest::Double::get_doubled' => { source => 'get_doubled', is_xs_native => 1 },
        },
    ), 'XS::JIT compilation succeeded');
    
    # Test the compiled function
    package CustomOpTest::Double;
    sub new { bless [10, 20, 30], shift }
    
    package main;
    my $obj = CustomOpTest::Double->new;
    is($obj->get_doubled(0), 20, 'get_doubled slot 0: 10 * 2 = 20');
    is($obj->get_doubled(1), 40, 'get_doubled slot 1: 20 * 2 = 40');
    is($obj->get_doubled(2), 60, 'get_doubled slot 2: 30 * 2 = 60');
};

subtest 'JIT compile xop and checker' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Build pp function FIRST (before xop_declare which references it)
    $b->pp_start('getter')
      ->pp_dsp
      ->pp_get_self
      ->pp_get_slots
      ->line('IV slot = PL_op->op_targ;')
      ->line('SV* val = ary[slot] ? ary[slot] : &PL_sv_undef;')
      ->pp_return_sv('val')
      ->pp_end;
    
    # Declare XOP after pp function is defined
    $b->xop_declare('getter_xop', 'S_pp_getter', 'slot getter');
    
    # Build call checker
    $b->ck_start('getter')
      ->ck_preamble
      ->line('IV slot = SvIV(ckobj);')
      ->ck_build_unop('S_pp_getter', 'slot')
      ->ck_end;
    
    # Also add a testable XS function
    $b->xs_function('get_slot')
      ->xs_preamble
      ->check_items(2, 2, '$self, $slot')
      ->get_self
      ->line('AV* av = (AV*)SvRV(self);')
      ->line('IV slot = SvIV(ST(1));')
      ->line('SV** elem = av_fetch(av, slot, 0);')
      ->if('elem && *elem')
        ->return_sv('*elem')
      ->endif
      ->return_undef
      ->xs_end;
    
    my $code = $b->code;
    
    # Verify all components were generated
    like($code, qr/static\s+XOP\s+xop_getter_xop/, 'XOP declared');
    like($code, qr/S_pp_getter/, 'pp function generated');
    like($code, qr/S_ck_getter/, 'call checker generated');
    like($code, qr/Perl_custom_op_register/, 'XOP registration code');
    like($code, qr/OP_CUSTOM/, 'uses OP_CUSTOM');
    
    # Compile with XS::JIT
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'CustomOpTest::Getter',
        cache_dir => $cache_dir,
        functions => {
            'CustomOpTest::Getter::get_slot' => { source => 'get_slot', is_xs_native => 1 },
        },
    ), 'XS::JIT compilation succeeded with xop/ck code');
    
    # Test the compiled function
    package CustomOpTest::Getter;
    sub new { bless ['first', 'second', 'third'], shift }
    
    package main;
    my $obj = CustomOpTest::Getter->new;
    is($obj->get_slot(0), 'first', 'get_slot 0');
    is($obj->get_slot(1), 'second', 'get_slot 1');
    is($obj->get_slot(2), 'third', 'get_slot 2');
};

done_testing;
