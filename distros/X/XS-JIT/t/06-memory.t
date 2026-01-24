#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);

# Skip if Test::LeakTrace not available
BEGIN {
    eval { require Test::LeakTrace };
    if ($@) {
        plan skip_all => 'Test::LeakTrace not installed';
    }
}

use Test::LeakTrace;

my $cache_dir = '_CACHED_XS_test_memory';
remove_tree($cache_dir) if -d $cache_dir;

use_ok('XS::JIT');

# Pre-compile all test modules so compilation itself doesn't interfere with leak tests
my $int_code = <<'C_CODE';
SV* mem_int_test(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) return newSViv(0);
    return newSViv(SvIV(ST(1)) * 2);
}
C_CODE

my $str_code = <<'C_CODE';
SV* mem_str_test(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) return newSVpv("", 0);
    STRLEN len;
    const char* s = SvPV(ST(1), len);
    SV* result = newSVpvn(s, len);
    sv_catpvn(result, s, len);
    return result;
}
C_CODE

my $obj_code = <<'C_CODE';
SV* mem_obj_new(SV* class_sv, ...) {
    dTHX;
    const char* classname = SvPV_nolen(class_sv);
    HV* self_hv = newHV();
    hv_store(self_hv, "data", 4, newSViv(0), 0);
    return sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));
}

SV* mem_obj_get(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** val = hv_fetch(hv, "data", 4, 0);
    return val ? newSVsv(*val) : &PL_sv_undef;
}

SV* mem_obj_set(SV* self, ...) {
    dTHX;
    dXSARGS;
    HV* hv = (HV*)SvRV(self);
    if (items >= 2) {
        hv_store(hv, "data", 4, newSVsv(ST(1)), 0);
        return newSVsv(ST(1));
    }
    return &PL_sv_undef;
}
C_CODE

my $arr_code = <<'C_CODE';
SV* mem_arr_create(SV* self, ...) {
    JIT_ARGS;
    AV* av = newAV();
    int i;
    for (i = 1; i < items; i++) {
        av_push(av, newSVsv(ST(i)));
    }
    return newRV_noinc((SV*)av);
}

SV* mem_arr_sum(SV* self, ...) {
    JIT_ARGS;
    if (items < 2 || !SvROK(ST(1))) return newSViv(0);
    AV* av = (AV*)SvRV(ST(1));
    IV sum = 0;
    IV len = av_len(av) + 1;
    IV i;
    for (i = 0; i < len; i++) {
        SV** elem = av_fetch(av, i, 0);
        if (elem) sum += SvIV(*elem);
    }
    return newSViv(sum);
}
C_CODE

# Compile all before leak tests
{
    package MemInt;
    XS::JIT->compile(
        code => $int_code, name => 'MemInt::JIT_0',
        functions => { 'MemInt::double' => 'mem_int_test' },
        cache_dir => $cache_dir,
    );
}

{
    package MemStr;
    XS::JIT->compile(
        code => $str_code, name => 'MemStr::JIT_0',
        functions => { 'MemStr::dupe' => 'mem_str_test' },
        cache_dir => $cache_dir,
    );
}

{
    package MemObj;
    XS::JIT->compile(
        code => $obj_code, name => 'MemObj::JIT_0',
        functions => {
            'MemObj::new' => 'mem_obj_new',
            'MemObj::get' => 'mem_obj_get',
            'MemObj::set' => 'mem_obj_set',
        },
        cache_dir => $cache_dir,
    );
}

{
    package MemArr;
    XS::JIT->compile(
        code => $arr_code, name => 'MemArr::JIT_0',
        functions => {
            'MemArr::create' => 'mem_arr_create',
            'MemArr::sum'    => 'mem_arr_sum',
        },
        cache_dir => $cache_dir,
    );
}

# Test 1: Integer operations don't leak
{
    no_leaks_ok {
        for (1..100) {
            my $r = MemInt->double(42);
        }
    } 'Integer operations do not leak';
}

# Test 2: String operations don't leak
{
    no_leaks_ok {
        for (1..100) {
            my $r = MemStr->dupe("test");
        }
    } 'String operations do not leak';
}

# Test 3: Object creation/destruction doesn't leak
{
    no_leaks_ok {
        for (1..100) {
            my $obj = MemObj->new;
            $obj->set(42);
            my $v = $obj->get;
        }
    } 'Object creation and access do not leak';
}

# Test 4: Array reference operations don't leak
{
    no_leaks_ok {
        for (1..100) {
            my $arr = MemArr->create(1, 2, 3, 4, 5);
            my $sum = MemArr->sum($arr);
        }
    } 'Array operations do not leak';
}

# Test 5: Repeated object operations don't leak
{
    no_leaks_ok {
        my $obj = MemObj->new;
        for (1..100) {
            $obj->set($_);
            my $v = $obj->get;
        }
    } 'Repeated object access does not leak';
}

# Test 6: Large string operations don't leak
{
    no_leaks_ok {
        my $big = 'x' x 10000;
        for (1..50) {
            my $r = MemStr->dupe($big);
        }
    } 'Large string operations do not leak';
}

# Test 7: Many small objects don't leak
{
    no_leaks_ok {
        my @objs;
        for (1..100) {
            push @objs, MemObj->new;
        }
        for my $obj (@objs) {
            $obj->set(1);
        }
        @objs = ();  # Clear all objects
    } 'Many objects do not leak';
}

# Test 8: Nested array operations don't leak
{
    no_leaks_ok {
        for (1..50) {
            my $a1 = MemArr->create(1, 2, 3);
            my $a2 = MemArr->create(4, 5, 6);
            my $s1 = MemArr->sum($a1);
            my $s2 = MemArr->sum($a2);
        }
    } 'Nested array operations do not leak';
}

# Test 9: Mixed operations don't leak
{
    no_leaks_ok {
        for (1..50) {
            my $i = MemInt->double(21);
            my $s = MemStr->dupe("test");
            my $o = MemObj->new;
            $o->set($i);
            my $a = MemArr->create($o->get, $o->get);
        }
    } 'Mixed operations do not leak';
}

# Test 10: Stress test with many iterations
{
    no_leaks_ok {
        for (1..1000) {
            my $x = MemInt->double($_ % 100);
        }
    } 'Stress test (1000 iterations) does not leak';
}

# Clean up
remove_tree($cache_dir) if -d $cache_dir;

done_testing();
