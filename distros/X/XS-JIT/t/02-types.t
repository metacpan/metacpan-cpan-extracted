#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);

my $cache_dir = '_CACHED_XS_test_types';
remove_tree($cache_dir) if -d $cache_dir;

use_ok('XS::JIT');

# Test various data types

# Integer operations
{
    package IntTest;

    my $code = <<'C_CODE';
SV* int_identity(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("int_identity requires 1 argument");
    return newSViv(SvIV(ST(1)));
}

SV* int_negate(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("int_negate requires 1 argument");
    return newSViv(-SvIV(ST(1)));
}

SV* int_abs(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("int_abs requires 1 argument");
    IV val = SvIV(ST(1));
    return newSViv(val < 0 ? -val : val);
}

SV* int_max(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("int_max requires 2 arguments");
    IV a = SvIV(ST(1));
    IV b = SvIV(ST(2));
    return newSViv(a > b ? a : b);
}

SV* int_min(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("int_min requires 2 arguments");
    IV a = SvIV(ST(1));
    IV b = SvIV(ST(2));
    return newSViv(a < b ? a : b);
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'IntTest::JIT_0',
        functions => {
            'IntTest::identity' => 'int_identity',
            'IntTest::negate'   => 'int_negate',
            'IntTest::abs'      => 'int_abs',
            'IntTest::max'      => 'int_max',
            'IntTest::min'      => 'int_min',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'IntTest compiles');

    # Identity
    main::is(IntTest->identity(42), 42, 'identity(42) = 42');
    main::is(IntTest->identity(0), 0, 'identity(0) = 0');
    main::is(IntTest->identity(-100), -100, 'identity(-100) = -100');

    # Negate
    main::is(IntTest->negate(5), -5, 'negate(5) = -5');
    main::is(IntTest->negate(-10), 10, 'negate(-10) = 10');
    main::is(IntTest->negate(0), 0, 'negate(0) = 0');

    # Abs
    main::is(IntTest->abs(5), 5, 'abs(5) = 5');
    main::is(IntTest->abs(-5), 5, 'abs(-5) = 5');
    main::is(IntTest->abs(0), 0, 'abs(0) = 0');

    # Max/Min
    main::is(IntTest->max(3, 7), 7, 'max(3, 7) = 7');
    main::is(IntTest->max(10, 2), 10, 'max(10, 2) = 10');
    main::is(IntTest->min(3, 7), 3, 'min(3, 7) = 3');
    main::is(IntTest->min(10, 2), 2, 'min(10, 2) = 2');
}

# Float/Number operations
{
    package NumTest;

    my $code = <<'C_CODE';
SV* num_identity(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("num_identity requires 1 argument");
    return newSVnv(SvNV(ST(1)));
}

SV* num_add(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("num_add requires 2 arguments");
    NV a = SvNV(ST(1));
    NV b = SvNV(ST(2));
    return newSVnv(a + b);
}

SV* num_multiply(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("num_multiply requires 2 arguments");
    NV a = SvNV(ST(1));
    NV b = SvNV(ST(2));
    return newSVnv(a * b);
}

SV* num_divide(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("num_divide requires 2 arguments");
    NV a = SvNV(ST(1));
    NV b = SvNV(ST(2));
    if (b == 0) croak("Division by zero");
    return newSVnv(a / b);
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'NumTest::JIT_0',
        functions => {
            'NumTest::identity' => 'num_identity',
            'NumTest::add'      => 'num_add',
            'NumTest::multiply' => 'num_multiply',
            'NumTest::divide'   => 'num_divide',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'NumTest compiles');

    # Identity
    main::is(NumTest->identity(3.14), 3.14, 'identity(3.14) = 3.14');
    main::is(NumTest->identity(0.0), 0, 'identity(0.0) = 0');

    # Add
    main::is(NumTest->add(1.5, 2.5), 4.0, 'add(1.5, 2.5) = 4.0');
    main::is(NumTest->add(-1.0, 1.0), 0, 'add(-1.0, 1.0) = 0');

    # Multiply
    main::is(NumTest->multiply(2.0, 3.0), 6.0, 'multiply(2.0, 3.0) = 6.0');
    main::is(NumTest->multiply(0.5, 4.0), 2.0, 'multiply(0.5, 4.0) = 2.0');

    # Divide
    main::is(NumTest->divide(10.0, 2.0), 5.0, 'divide(10.0, 2.0) = 5.0');
    main::is(NumTest->divide(1.0, 4.0), 0.25, 'divide(1.0, 4.0) = 0.25');
}

# String operations
{
    package StrTest;

    my $code = <<'C_CODE';
SV* str_identity(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("str_identity requires 1 argument");
    STRLEN len;
    const char* str = SvPV(ST(1), len);
    return newSVpvn(str, len);
}

SV* str_length(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("str_length requires 1 argument");
    STRLEN len;
    SvPV(ST(1), len);
    return newSViv((IV)len);
}

SV* str_concat(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("str_concat requires 2 arguments");
    STRLEN len1, len2;
    const char* str1 = SvPV(ST(1), len1);
    const char* str2 = SvPV(ST(2), len2);
    SV* result = newSVpvn(str1, len1);
    sv_catpvn(result, str2, len2);
    return result;
}

SV* str_repeat(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("str_repeat requires 2 arguments");
    STRLEN len;
    const char* str = SvPV(ST(1), len);
    IV count = SvIV(ST(2));
    SV* result = newSVpvn("", 0);
    for (IV i = 0; i < count; i++) {
        sv_catpvn(result, str, len);
    }
    return result;
}

SV* str_upper(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("str_upper requires 1 argument");
    STRLEN len;
    const char* str = SvPV(ST(1), len);
    SV* result = newSVpvn(str, len);
    char* p = SvPVX(result);
    for (STRLEN i = 0; i < len; i++) {
        if (p[i] >= 'a' && p[i] <= 'z') {
            p[i] = p[i] - 'a' + 'A';
        }
    }
    return result;
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'StrTest::JIT_0',
        functions => {
            'StrTest::identity' => 'str_identity',
            'StrTest::length'   => 'str_length',
            'StrTest::concat'   => 'str_concat',
            'StrTest::repeat'   => 'str_repeat',
            'StrTest::upper'    => 'str_upper',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'StrTest compiles');

    # Identity
    main::is(StrTest->identity("hello"), "hello", 'identity("hello") = "hello"');
    main::is(StrTest->identity(""), "", 'identity("") = ""');
    main::is(StrTest->identity("with spaces"), "with spaces", 'identity preserves spaces');

    # Length
    main::is(StrTest->length("hello"), 5, 'length("hello") = 5');
    main::is(StrTest->length(""), 0, 'length("") = 0');
    main::is(StrTest->length("abc"), 3, 'length("abc") = 3');

    # Concat
    main::is(StrTest->concat("foo", "bar"), "foobar", 'concat("foo", "bar") = "foobar"');
    main::is(StrTest->concat("", "test"), "test", 'concat("", "test") = "test"');
    main::is(StrTest->concat("test", ""), "test", 'concat("test", "") = "test"');

    # Repeat
    main::is(StrTest->repeat("ab", 3), "ababab", 'repeat("ab", 3) = "ababab"');
    main::is(StrTest->repeat("x", 5), "xxxxx", 'repeat("x", 5) = "xxxxx"');
    main::is(StrTest->repeat("test", 0), "", 'repeat("test", 0) = ""');

    # Upper
    main::is(StrTest->upper("hello"), "HELLO", 'upper("hello") = "HELLO"');
    main::is(StrTest->upper("HeLLo"), "HELLO", 'upper("HeLLo") = "HELLO"');
    main::is(StrTest->upper("123"), "123", 'upper("123") = "123"');
}

# Array reference operations
{
    package ArrayTest;

    my $code = <<'C_CODE';
SV* arr_length(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("arr_length requires 1 argument");
    SV* arg = ST(1);
    if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV) {
        croak("Argument must be an array reference");
    }
    AV* av = (AV*)SvRV(arg);
    return newSViv(av_len(av) + 1);
}

SV* arr_get(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("arr_get requires 2 arguments");
    SV* arg = ST(1);
    if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV) {
        croak("First argument must be an array reference");
    }
    AV* av = (AV*)SvRV(arg);
    IV idx = SvIV(ST(2));
    SV** elem = av_fetch(av, idx, 0);
    if (elem && *elem) {
        return newSVsv(*elem);
    }
    return &PL_sv_undef;
}

SV* arr_sum(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("arr_sum requires 1 argument");
    SV* arg = ST(1);
    if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV) {
        croak("Argument must be an array reference");
    }
    AV* av = (AV*)SvRV(arg);
    IV len = av_len(av) + 1;
    NV sum = 0;
    for (IV i = 0; i < len; i++) {
        SV** elem = av_fetch(av, i, 0);
        if (elem && *elem) {
            sum += SvNV(*elem);
        }
    }
    return newSVnv(sum);
}

SV* arr_reverse(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("arr_reverse requires 1 argument");
    SV* arg = ST(1);
    if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV) {
        croak("Argument must be an array reference");
    }
    AV* av = (AV*)SvRV(arg);
    IV len = av_len(av) + 1;
    AV* result = newAV();
    for (IV i = len - 1; i >= 0; i--) {
        SV** elem = av_fetch(av, i, 0);
        if (elem && *elem) {
            av_push(result, newSVsv(*elem));
        }
    }
    return newRV_noinc((SV*)result);
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'ArrayTest::JIT_0',
        functions => {
            'ArrayTest::length'  => 'arr_length',
            'ArrayTest::get'     => 'arr_get',
            'ArrayTest::sum'     => 'arr_sum',
            'ArrayTest::reverse' => 'arr_reverse',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'ArrayTest compiles');

    # Length
    main::is(ArrayTest->length([1, 2, 3]), 3, 'length([1,2,3]) = 3');
    main::is(ArrayTest->length([]), 0, 'length([]) = 0');
    main::is(ArrayTest->length([1, 2, 3, 4, 5]), 5, 'length([1,2,3,4,5]) = 5');

    # Get
    main::is(ArrayTest->get([10, 20, 30], 0), 10, 'get([10,20,30], 0) = 10');
    main::is(ArrayTest->get([10, 20, 30], 1), 20, 'get([10,20,30], 1) = 20');
    main::is(ArrayTest->get([10, 20, 30], 2), 30, 'get([10,20,30], 2) = 30');

    # Sum
    main::is(ArrayTest->sum([1, 2, 3, 4]), 10, 'sum([1,2,3,4]) = 10');
    main::is(ArrayTest->sum([]), 0, 'sum([]) = 0');
    main::is(ArrayTest->sum([1.5, 2.5]), 4.0, 'sum([1.5, 2.5]) = 4.0');

    # Reverse
    main::is_deeply(ArrayTest->reverse([1, 2, 3]), [3, 2, 1], 'reverse([1,2,3]) = [3,2,1]');
    main::is_deeply(ArrayTest->reverse([]), [], 'reverse([]) = []');
    main::is_deeply(ArrayTest->reverse(['a', 'b']), ['b', 'a'], 'reverse(["a","b"]) = ["b","a"]');
}

# Hash reference operations
{
    package HashTest;

    my $code = <<'C_CODE';
SV* hash_keys_count(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("hash_keys_count requires 1 argument");
    SV* arg = ST(1);
    if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVHV) {
        croak("Argument must be a hash reference");
    }
    HV* hv = (HV*)SvRV(arg);
    return newSViv(HvKEYS(hv));
}

SV* hash_get(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("hash_get requires 2 arguments");
    SV* arg = ST(1);
    if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVHV) {
        croak("First argument must be a hash reference");
    }
    HV* hv = (HV*)SvRV(arg);
    STRLEN klen;
    const char* key = SvPV(ST(2), klen);
    SV** val = hv_fetch(hv, key, klen, 0);
    if (val && *val) {
        return newSVsv(*val);
    }
    return &PL_sv_undef;
}

SV* hash_exists(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("hash_exists requires 2 arguments");
    SV* arg = ST(1);
    if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVHV) {
        croak("First argument must be a hash reference");
    }
    HV* hv = (HV*)SvRV(arg);
    STRLEN klen;
    const char* key = SvPV(ST(2), klen);
    return hv_exists(hv, key, klen) ? &PL_sv_yes : &PL_sv_no;
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'HashTest::JIT_0',
        functions => {
            'HashTest::keys_count' => 'hash_keys_count',
            'HashTest::get'        => 'hash_get',
            'HashTest::exists'     => 'hash_exists',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'HashTest compiles');

    # Keys count
    main::is(HashTest->keys_count({a => 1, b => 2}), 2, 'keys_count({a=>1,b=>2}) = 2');
    main::is(HashTest->keys_count({}), 0, 'keys_count({}) = 0');

    # Get
    main::is(HashTest->get({foo => 'bar'}, 'foo'), 'bar', 'get({foo=>"bar"}, "foo") = "bar"');
    main::ok(!defined HashTest->get({foo => 'bar'}, 'baz'), 'get({foo=>"bar"}, "baz") = undef');

    # Exists
    main::ok(HashTest->exists({foo => 1}, 'foo'), 'exists({foo=>1}, "foo") = true');
    main::ok(!HashTest->exists({foo => 1}, 'bar'), 'exists({foo=>1}, "bar") = false');
}

# Clean up
remove_tree($cache_dir) if -d $cache_dir;

done_testing();
