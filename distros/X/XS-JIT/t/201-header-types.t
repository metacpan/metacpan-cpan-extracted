#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('XS::JIT::Header::TypeMap');
}

# Comprehensive type mapping tests
subtest 'Basic integer types' => sub {
    my @signed = qw(char short int long);
    for my $type (@signed) {
        my $info = XS::JIT::Header::TypeMap::resolve($type);
        ok($info, "resolve $type");
        is($info->{perl}, 'IV', "$type maps to IV");
        is($info->{convert}, 'SvIV', "$type uses SvIV");
        is($info->{create}, 'newSViv', "$type uses newSViv");
    }

    my @unsigned = ('unsigned char', 'unsigned short', 'unsigned int', 'unsigned long');
    for my $type (@unsigned) {
        my $info = XS::JIT::Header::TypeMap::resolve($type);
        ok($info, "resolve $type");
        is($info->{perl}, 'UV', "$type maps to UV");
        is($info->{convert}, 'SvUV', "$type uses SvUV");
        is($info->{create}, 'newSVuv', "$type uses newSVuv");
    }
};

subtest 'Long long types' => sub {
    my $info = XS::JIT::Header::TypeMap::resolve('long long');
    ok($info, 'resolve long long');
    is($info->{perl}, 'IV', 'long long maps to IV');

    $info = XS::JIT::Header::TypeMap::resolve('unsigned long long');
    ok($info, 'resolve unsigned long long');
    is($info->{perl}, 'UV', 'unsigned long long maps to UV');
};

subtest 'Floating point types' => sub {
    for my $type (qw(float double)) {
        my $info = XS::JIT::Header::TypeMap::resolve($type);
        ok($info, "resolve $type");
        is($info->{perl}, 'NV', "$type maps to NV");
        is($info->{convert}, 'SvNV', "$type uses SvNV");
        is($info->{create}, 'newSVnv', "$type uses newSVnv");
    }

    my $info = XS::JIT::Header::TypeMap::resolve('long double');
    ok($info, 'resolve long double');
    is($info->{perl}, 'NV', 'long double maps to NV');
};

subtest 'String types' => sub {
    for my $type ('char*', 'char *', 'const char*', 'const char *') {
        my $info = XS::JIT::Header::TypeMap::resolve($type);
        ok($info, "resolve '$type'");
        is($info->{perl}, 'PV', "'$type' maps to PV");
        is($info->{convert}, 'SvPV_nolen', "'$type' uses SvPV_nolen");
    }
};

subtest 'Void type' => sub {
    my $info = XS::JIT::Header::TypeMap::resolve('void');
    ok($info, 'resolve void');
    is($info->{perl}, 'void', 'void maps to void');
    ok(!defined $info->{convert}, 'void has no convert');
    ok(!defined $info->{create}, 'void has no create');
};

subtest 'Pointer types' => sub {
    my $info = XS::JIT::Header::TypeMap::resolve('void*');
    ok($info, 'resolve void*');
    is($info->{perl}, 'UV', 'void* maps to UV');
    ok($info->{is_ptr}, 'void* marked as pointer');
    is($info->{convert}, 'PTR2UV', 'void* uses PTR2UV');

    $info = XS::JIT::Header::TypeMap::resolve('int*');
    ok($info, 'resolve int*');
    is($info->{perl}, 'UV', 'int* maps to UV');
    ok($info->{is_ptr}, 'int* marked as pointer');

    $info = XS::JIT::Header::TypeMap::resolve('double*');
    ok($info, 'resolve double*');
    is($info->{perl}, 'UV', 'double* maps to UV');
    ok($info->{is_ptr}, 'double* marked as pointer');
};

subtest 'Fixed-width integer types (C99)' => sub {
    my %expected = (
        'int8_t'   => 'IV',
        'int16_t'  => 'IV',
        'int32_t'  => 'IV',
        'int64_t'  => 'IV',
        'uint8_t'  => 'UV',
        'uint16_t' => 'UV',
        'uint32_t' => 'UV',
        'uint64_t' => 'UV',
    );

    for my $type (sort keys %expected) {
        my $info = XS::JIT::Header::TypeMap::resolve($type);
        ok($info, "resolve $type");
        is($info->{perl}, $expected{$type}, "$type maps to $expected{$type}");
    }
};

subtest 'Size types' => sub {
    my $info = XS::JIT::Header::TypeMap::resolve('size_t');
    ok($info, 'resolve size_t');
    is($info->{perl}, 'UV', 'size_t maps to UV');

    $info = XS::JIT::Header::TypeMap::resolve('ssize_t');
    ok($info, 'resolve ssize_t');
    is($info->{perl}, 'IV', 'ssize_t maps to IV');

    $info = XS::JIT::Header::TypeMap::resolve('ptrdiff_t');
    ok($info, 'resolve ptrdiff_t');
    is($info->{perl}, 'IV', 'ptrdiff_t maps to IV');
};

subtest 'Type normalization' => sub {
    # Whitespace normalization
    is(XS::JIT::Header::TypeMap::normalize_type('  int  '), 'int', 'trim whitespace');
    is(XS::JIT::Header::TypeMap::normalize_type('unsigned  int'), 'unsigned int', 'collapse internal whitespace');

    # Pointer normalization
    is(XS::JIT::Header::TypeMap::normalize_type('char *'), 'char*', 'normalize char *');
    is(XS::JIT::Header::TypeMap::normalize_type('char  *'), 'char*', 'normalize char  *');
    is(XS::JIT::Header::TypeMap::normalize_type('char* *'), 'char**', 'normalize char* *');
};

subtest 'Unknown types' => sub {
    my $info = XS::JIT::Header::TypeMap::resolve('MyCustomType');
    ok($info, 'resolve unknown type');
    is($info->{perl}, 'UV', 'unknown type maps to UV');
    ok($info->{opaque}, 'unknown type marked as opaque');
    ok($info->{unknown}, 'unknown type marked as unknown');

    $info = XS::JIT::Header::TypeMap::resolve('struct foo');
    ok($info, 'resolve struct foo');
    ok($info->{unknown}, 'struct marked as unknown');
};

subtest 'Type registration' => sub {
    XS::JIT::Header::TypeMap::register('MyInt',
        perl    => 'IV',
        c       => 'MyInt',
        convert => 'SvIV',
        create  => 'newSViv',
    );

    my $info = XS::JIT::Header::TypeMap::resolve('MyInt');
    ok($info, 'resolve registered type');
    is($info->{perl}, 'IV', 'registered type has correct perl type');
    ok(!$info->{unknown}, 'registered type not marked as unknown');
};

subtest 'Type aliases' => sub {
    XS::JIT::Header::TypeMap::alias('BOOL', 'int');

    my $info = XS::JIT::Header::TypeMap::resolve('BOOL');
    ok($info, 'resolve aliased type');
    is($info->{perl}, 'IV', 'aliased type maps correctly');
    is($info->{c}, 'BOOL', 'aliased type keeps its name');
};

subtest 'is_known function' => sub {
    ok(XS::JIT::Header::TypeMap::is_known('int'), 'int is known');
    ok(XS::JIT::Header::TypeMap::is_known('double'), 'double is known');
    ok(XS::JIT::Header::TypeMap::is_known('char*'), 'char* is known');
    ok(!XS::JIT::Header::TypeMap::is_known('UnknownType'), 'UnknownType is not known');
};

done_testing;
