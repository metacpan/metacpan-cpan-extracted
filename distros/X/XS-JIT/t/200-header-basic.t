#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    use_ok('XS::JIT::Header');
    use_ok('XS::JIT::Header::Parser');
    use_ok('XS::JIT::Header::TypeMap');
}

# Test TypeMap
subtest 'TypeMap basics' => sub {
    my $info = XS::JIT::Header::TypeMap::resolve('int');
    ok($info, 'resolve int');
    is($info->{perl}, 'IV', 'int maps to IV');
    is($info->{convert}, 'SvIV', 'int converts with SvIV');
    is($info->{create}, 'newSViv', 'int creates with newSViv');

    $info = XS::JIT::Header::TypeMap::resolve('double');
    ok($info, 'resolve double');
    is($info->{perl}, 'NV', 'double maps to NV');

    $info = XS::JIT::Header::TypeMap::resolve('char*');
    ok($info, 'resolve char*');
    is($info->{perl}, 'PV', 'char* maps to PV');

    $info = XS::JIT::Header::TypeMap::resolve('void');
    ok($info, 'resolve void');
    is($info->{perl}, 'void', 'void maps to void');

    $info = XS::JIT::Header::TypeMap::resolve('void*');
    ok($info, 'resolve void*');
    is($info->{perl}, 'UV', 'void* maps to UV');
    ok($info->{is_ptr}, 'void* is marked as pointer');
};

subtest 'TypeMap normalization' => sub {
    my $info1 = XS::JIT::Header::TypeMap::resolve('char *');
    my $info2 = XS::JIT::Header::TypeMap::resolve('char*');
    is($info1->{perl}, $info2->{perl}, 'char * and char* resolve same');

    $info1 = XS::JIT::Header::TypeMap::resolve('unsigned int');
    ok($info1, 'resolve unsigned int');
    is($info1->{perl}, 'UV', 'unsigned int maps to UV');

    $info1 = XS::JIT::Header::TypeMap::resolve('const char*');
    ok($info1, 'resolve const char*');
    is($info1->{perl}, 'PV', 'const char* maps to PV');
};

subtest 'TypeMap pointer types' => sub {
    my $info = XS::JIT::Header::TypeMap::resolve('int*');
    ok($info, 'resolve int*');
    is($info->{perl}, 'UV', 'int* maps to UV');
    ok($info->{is_ptr}, 'int* is marked as pointer');

    $info = XS::JIT::Header::TypeMap::resolve('double**');
    ok($info, 'resolve double**');
    is($info->{perl}, 'UV', 'double** maps to UV');
    ok($info->{is_ptr}, 'double** is marked as pointer');
};

subtest 'TypeMap fixed-width integers' => sub {
    for my $type (qw(int8_t int16_t int32_t int64_t)) {
        my $info = XS::JIT::Header::TypeMap::resolve($type);
        ok($info, "resolve $type");
        is($info->{perl}, 'IV', "$type maps to IV");
    }

    for my $type (qw(uint8_t uint16_t uint32_t uint64_t size_t)) {
        my $info = XS::JIT::Header::TypeMap::resolve($type);
        ok($info, "resolve $type");
        is($info->{perl}, 'UV', "$type maps to UV");
    }
};

# Test Parser with inline header
subtest 'Parser basics' => sub {
    my $parser = XS::JIT::Header::Parser->new;
    ok($parser, 'create parser');

    my $header_content = <<'HEADER';
#define VERSION 1
#define PI 3.14159

int add(int a, int b);
double multiply(double x, double y);
void print_message(const char* msg);
char* get_name(void);
HEADER

    $parser->parse_string($header_content);

    my @funcs = $parser->function_names;
    ok(scalar @funcs >= 4, 'parsed at least 4 functions');
    ok((grep { $_ eq 'add' } @funcs), 'found add function');
    ok((grep { $_ eq 'multiply' } @funcs), 'found multiply function');

    my $add = $parser->function('add');
    ok($add, 'get add function info');
    is($add->{return_type}, 'int', 'add returns int');
    is(scalar @{$add->{params}}, 2, 'add has 2 params');

    my $multiply = $parser->function('multiply');
    ok($multiply, 'get multiply function info');
    is($multiply->{return_type}, 'double', 'multiply returns double');

    # Constants
    my @consts = $parser->constant_names;
    ok((grep { $_ eq 'VERSION' } @consts), 'found VERSION constant');
    ok((grep { $_ eq 'PI' } @consts), 'found PI constant');

    my $version = $parser->constant('VERSION');
    is($version->{value}, 1, 'VERSION value is 1');

    my $pi = $parser->constant('PI');
    ok(abs($pi->{value} - 3.14159) < 0.0001, 'PI value is approximately 3.14159');
};

subtest 'Parser complex types' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header_content = <<'HEADER';
unsigned long get_size(void);
const char* get_string(int index);
void* alloc_memory(size_t size);
long long big_number(void);
HEADER

    $parser->parse_string($header_content);

    my $get_size = $parser->function('get_size');
    ok($get_size, 'get get_size function');
    like($get_size->{return_type}, qr/unsigned\s+long/, 'get_size returns unsigned long');

    my $get_string = $parser->function('get_string');
    ok($get_string, 'get get_string function');
    like($get_string->{return_type}, qr/const\s+char\s*\*/, 'get_string returns const char*');

    my $alloc = $parser->function('alloc_memory');
    ok($alloc, 'get alloc_memory function');
    like($alloc->{return_type}, qr/void\s*\*/, 'alloc_memory returns void*');
};

subtest 'Parser enums' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header_content = <<'HEADER';
enum Color {
    RED,
    GREEN,
    BLUE,
    YELLOW = 10,
    ORANGE
};
HEADER

    $parser->parse_string($header_content);

    my @consts = $parser->constant_names;
    ok((grep { $_ eq 'RED' } @consts), 'found RED constant');
    ok((grep { $_ eq 'GREEN' } @consts), 'found GREEN constant');
    ok((grep { $_ eq 'BLUE' } @consts), 'found BLUE constant');
    ok((grep { $_ eq 'YELLOW' } @consts), 'found YELLOW constant');
    ok((grep { $_ eq 'ORANGE' } @consts), 'found ORANGE constant');

    is($parser->constant('RED')->{value}, 0, 'RED = 0');
    is($parser->constant('GREEN')->{value}, 1, 'GREEN = 1');
    is($parser->constant('BLUE')->{value}, 2, 'BLUE = 2');
    is($parser->constant('YELLOW')->{value}, 10, 'YELLOW = 10');
    is($parser->constant('ORANGE')->{value}, 11, 'ORANGE = 11');
};

# Test Header module constructor
subtest 'Header constructor' => sub {
    # Test with non-existent header (should fail)
    eval {
        my $h = XS::JIT::Header->new(
            header => '/nonexistent/path/to/header.h',
        );
    };
    ok($@, 'dies with non-existent header');
    like($@, qr/Cannot find/, 'error mentions cannot find');
};

done_testing;
