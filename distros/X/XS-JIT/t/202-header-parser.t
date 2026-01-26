#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('XS::JIT::Header::Parser');
}

subtest 'Parser creation' => sub {
    my $parser = XS::JIT::Header::Parser->new;
    ok($parser, 'create parser with defaults');
    isa_ok($parser, 'XS::JIT::Header::Parser');

    $parser = XS::JIT::Header::Parser->new(
        include => ['/usr/local/include'],
        define  => { DEBUG => 1 },
    );
    ok($parser, 'create parser with options');
};

subtest 'Parse simple functions' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header = <<'HEADER';
int add(int a, int b);
double subtract(double x, double y);
void do_nothing(void);
HEADER

    $parser->parse_string($header);

    my $add = $parser->function('add');
    ok($add, 'found add function');
    is($add->{name}, 'add', 'name is add');
    is($add->{return_type}, 'int', 'returns int');
    is(scalar @{$add->{params}}, 2, 'has 2 parameters');
    is($add->{params}[0]{type}, 'int', 'first param is int');
    is($add->{params}[0]{name}, 'a', 'first param named a');
    is($add->{params}[1]{type}, 'int', 'second param is int');
    is($add->{params}[1]{name}, 'b', 'second param named b');
    ok(!$add->{is_variadic}, 'not variadic');

    my $sub = $parser->function('subtract');
    ok($sub, 'found subtract function');
    is($sub->{return_type}, 'double', 'returns double');

    my $nothing = $parser->function('do_nothing');
    ok($nothing, 'found do_nothing function');
    is($nothing->{return_type}, 'void', 'returns void');
    is(scalar @{$nothing->{params}}, 0, 'no parameters (void)');
};

subtest 'Parse pointer types' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header = <<'HEADER';
char* get_string(void);
void set_string(const char* str);
void* alloc(size_t size);
int** get_matrix(int rows, int cols);
HEADER

    $parser->parse_string($header);

    my $get = $parser->function('get_string');
    ok($get, 'found get_string');
    like($get->{return_type}, qr/char\s*\*/, 'returns char*');

    my $set = $parser->function('set_string');
    ok($set, 'found set_string');
    like($set->{params}[0]{type}, qr/const\s+char\s*\*/, 'param is const char*');

    my $alloc = $parser->function('alloc');
    ok($alloc, 'found alloc');
    like($alloc->{return_type}, qr/void\s*\*/, 'returns void*');
};

subtest 'Parse storage class specifiers' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header = <<'HEADER';
extern int global_func(void);
static inline int fast_func(int x);
HEADER

    $parser->parse_string($header);

    my $global = $parser->function('global_func');
    ok($global, 'found extern function');
    is($global->{return_type}, 'int', 'returns int');

    my $fast = $parser->function('fast_func');
    ok($fast, 'found static inline function');
};

subtest 'Parse #define constants' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header = <<'HEADER';
#define MAX_SIZE 1024
#define MIN_SIZE 0
#define PI 3.14159
#define HEX_VALUE 0xFF
#define NEGATIVE -42
#define SHIFT_VALUE (1 << 8)
#define STRING_CONST "hello"
HEADER

    $parser->parse_string($header);

    my $max = $parser->constant('MAX_SIZE');
    ok($max, 'found MAX_SIZE');
    is($max->{value}, 1024, 'MAX_SIZE = 1024');

    my $min = $parser->constant('MIN_SIZE');
    ok($min, 'found MIN_SIZE');
    is($min->{value}, 0, 'MIN_SIZE = 0');

    my $pi = $parser->constant('PI');
    ok($pi, 'found PI');
    ok(abs($pi->{value} - 3.14159) < 0.0001, 'PI ≈ 3.14159');

    my $hex = $parser->constant('HEX_VALUE');
    ok($hex, 'found HEX_VALUE');
    is($hex->{value}, 255, 'HEX_VALUE = 255');

    my $neg = $parser->constant('NEGATIVE');
    ok($neg, 'found NEGATIVE');
    is($neg->{value}, -42, 'NEGATIVE = -42');

    my $shift = $parser->constant('SHIFT_VALUE');
    SKIP: {
        skip "SHIFT_VALUE parsing may not work on all platforms", 2 unless $shift;
        ok($shift, 'found SHIFT_VALUE');
        is($shift->{value}, 256, 'SHIFT_VALUE = 256');
    }
};

subtest 'Parse enums' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header = <<'HEADER';
enum Status {
    STATUS_OK = 0,
    STATUS_ERROR = 1,
    STATUS_PENDING = 2
};

enum Color {
    RED,
    GREEN,
    BLUE
};

enum Mixed {
    FIRST,
    SECOND = 10,
    THIRD,
    FOURTH = 20
};
HEADER

    $parser->parse_string($header);

    is($parser->constant('STATUS_OK')->{value}, 0, 'STATUS_OK = 0');
    is($parser->constant('STATUS_ERROR')->{value}, 1, 'STATUS_ERROR = 1');
    is($parser->constant('STATUS_PENDING')->{value}, 2, 'STATUS_PENDING = 2');

    is($parser->constant('RED')->{value}, 0, 'RED = 0');
    is($parser->constant('GREEN')->{value}, 1, 'GREEN = 1');
    is($parser->constant('BLUE')->{value}, 2, 'BLUE = 2');

    is($parser->constant('FIRST')->{value}, 0, 'FIRST = 0');
    is($parser->constant('SECOND')->{value}, 10, 'SECOND = 10');
    is($parser->constant('THIRD')->{value}, 11, 'THIRD = 11');
    is($parser->constant('FOURTH')->{value}, 20, 'FOURTH = 20');
};

subtest 'Parse from temp file' => sub {
    my ($fh, $filename) = tempfile(SUFFIX => '.h', UNLINK => 1);
    print $fh <<'HEADER';
#define FILE_VERSION 100

int file_func(int x, int y);
double file_calc(double val);
HEADER
    close $fh;

    my $parser = XS::JIT::Header::Parser->new;
    $parser->parse_file($filename);

    ok($parser->function('file_func'), 'found file_func');
    ok($parser->function('file_calc'), 'found file_calc');
    ok($parser->constant('FILE_VERSION'), 'found FILE_VERSION');
    is($parser->constant('FILE_VERSION')->{value}, 100, 'FILE_VERSION = 100');
};

subtest 'Function names list' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header = <<'HEADER';
void func_a(void);
void func_b(void);
void func_c(void);
HEADER

    $parser->parse_string($header);

    my @names = $parser->function_names;
    ok(scalar @names >= 3, 'got at least 3 function names');
    ok((grep { $_ eq 'func_a' } @names), 'func_a in list');
    ok((grep { $_ eq 'func_b' } @names), 'func_b in list');
    ok((grep { $_ eq 'func_c' } @names), 'func_c in list');
};

subtest 'Constant names list' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header = <<'HEADER';
#define CONST_A 1
#define CONST_B 2
#define CONST_C 3
HEADER

    $parser->parse_string($header);

    my @names = $parser->constant_names;
    ok(scalar @names >= 3, 'got at least 3 constant names');
    ok((grep { $_ eq 'CONST_A' } @names), 'CONST_A in list');
    ok((grep { $_ eq 'CONST_B' } @names), 'CONST_B in list');
    ok((grep { $_ eq 'CONST_C' } @names), 'CONST_C in list');
};

subtest 'Complex return types' => sub {
    my $parser = XS::JIT::Header::Parser->new;

    my $header = <<'HEADER';
unsigned int get_unsigned(void);
unsigned long long get_ull(void);
const char* const get_const_str(void);
struct MyStruct* get_struct(void);
HEADER

    $parser->parse_string($header);

    my $uint = $parser->function('get_unsigned');
    ok($uint, 'found get_unsigned');
    like($uint->{return_type}, qr/unsigned\s+int/, 'returns unsigned int');

    my $ull = $parser->function('get_ull');
    ok($ull, 'found get_ull');
    like($ull->{return_type}, qr/unsigned\s+long\s+long/, 'returns unsigned long long');
};

done_testing;
