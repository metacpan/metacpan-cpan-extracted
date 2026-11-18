#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use builtin qw( true false is_bool );

no warnings 'experimental::builtin';

# Perl-side unit tests for Text::Nunjucks::Runtime (port of src/runtime.js) plus
# the ADR mechanisms it hosts and the Number->String routine added to Lib.
# render() does not exist yet (Environment/Compiler unported), so these exercise
# the runtime helpers DIRECTLY. Every expected value is oracle-grounded: it was
# derived from an equivalent template run through maint/oracle.js (the template
# is cited in the comment), never recalled. The end-to-end render-mode corpus
# cases that pin the same behaviour come with k16 (Environment).

use_ok('Text::Nunjucks::Runtime');
use_ok('Text::Nunjucks::Lib');

my $R = 'Text::Nunjucks::Runtime';
my $L = 'Text::Nunjucks::Lib';

# render-ish stringify helper for booleans/None/values, so an assertion reads
# the way the template's {{ ... }} output does.
sub s_ { my $v = shift; $R->_js_to_string($v) }

#### Number->String -- Lib->number_to_string (ADR 0007), oracle-grounded

subtest 'number_to_string (ECMAScript Number::toString)' => sub {
  # {{ 1/3 }} -> 0.3333333333333333, {{ 0.1 + 0.2 }} -> 0.30000000000000004
  is( $L->number_to_string( 1 / 3 ),     '0.3333333333333333',  '{{ 1/3 }}' );
  is( $L->number_to_string( 0.30000000000000004 ), '0.30000000000000004', '{{ 0.1 + 0.2 }} (the double, as a literal)' );
  is( $L->number_to_string( 10 / 4 ),    '2.5',                 '{{ 10/4 }}' );
  is( $L->number_to_string(100),         '100',                 '{{ 100 }}' );
  is( $L->number_to_string(3),           '3',                   'integer 3' );
  is( $L->number_to_string( 2 / 3 ),     '0.6666666666666666',  '{{ 2/3 }}' );
  is( $L->number_to_string( 22 / 7 ),    '3.142857142857143',   '{{ 22/7 }}' );
  is( $L->number_to_string( -1 / 3 ),    '-0.3333333333333333', 'negative sign' );

  # exponent thresholds (measured via computed values -- 1e21 does not lex)
  is( $L->number_to_string( 10**20 ), '100000000000000000000', '{{ 10 ** 20 }}' );
  is( $L->number_to_string( 10**21 ), '1e+21',                 '{{ 10 ** 21 }}' );
  is( $L->number_to_string( 10**22 ), '1e+22',                 '{{ 10 ** 22 }}' );
  is( $L->number_to_string( 1 / 1000000 ),  '0.000001', '{{ 1/1000000 }} (no exp)' );
  is( $L->number_to_string( 1 / 100000 ),   '0.00001',  '{{ 1/100000 }}' );
  is( $L->number_to_string( 1 / 10000000 ), '1e-7',     '{{ 1/10000000 }} (exp)' );
  is( $L->number_to_string( 1 / ( 10**21 ) ), '1e-21',  'small exponent' );

  # shortest round-trip on values Perl would keep as exact integers
  is( $L->number_to_string( 5**30 ), '931322574615478500000', '{{ 5 ** 30 }}' );
  is( $L->number_to_string( 2**53 ), '9007199254740992',      '{{ 2 ** 53 }}' );
  is( $L->number_to_string( 2**60 ), '1152921504606847000',   '{{ 2 ** 60 }}' );
  # big literal past double precision: parsed as a double, formatted shortest
  is( $L->number_to_string(1234567890123456789), '1234567890123456800', 'big int literal' );
  is( $L->number_to_string(9007199254740993),    '9007199254740992',    '2^53+1 rounds' );

  # specials
  my $inf = 9**9**9;
  is( $L->number_to_string($inf),    'Infinity',  '{{ 1/0 }}' );
  is( $L->number_to_string( -$inf ), '-Infinity', '{{ -1/0 }}' );
  is( $L->number_to_string( $inf - $inf ), 'NaN', '{{ 0/0 }}' );
  is( $L->number_to_string(0),    '0', 'zero' );
  is( $L->number_to_string(-0.0), '0', 'negative zero renders 0' );
};

#### JS operators -- Runtime (ADR 0007). Perl's native +,*,== lack JS semantics.

subtest 'op_add: add-or-concat by kind' => sub {
  is( s_( $R->op_add( 1, 1 ) ),        '2',  '{{ 1 + 1 }}' );
  is( s_( $R->op_add( '1', 1 ) ),      '11', q<{{ '1' + 1 }}> );
  is( s_( $R->op_add( '5', 3 ) ),      '53', q<{{ '5' + 3 }}> );
  is( s_( $R->op_add( true, 1 ) ),     '2',  '{{ true + 1 }}' );
  is( s_( $R->op_add( false, 1 ) ),    '1',  '{{ false + 1 }}' );
  is( s_( $R->op_add( 'a', 'b' ) ),    'ab', q<{{ 'a' + 'b' }}> );
  is( s_( $R->op_add( [ 1, 2 ], 1 ) ), '1,21', '{{ arr + 1 }} (array ToPrimitive)' );
  is( s_( $R->op_add( {}, 1 ) ),  '[object Object]1', '{{ o + 1 }}' );
  is( s_( $R->op_add( '', 5 ) ),  '5',  q<{{ '' + 5 }}> );
  # null + 1 -> 1 (null->0, numeric); none + 'y' -> "nully" (ToString(null))
  is( s_( $R->op_add( $R->None, 1 ) ),    '1',     '{{ n + 1 }} n=null (numeric)' );
  is( s_( $R->op_add( $R->None, 'y' ) ),  'nully', q<{{ none + 'y' }} (concat)> );
  is( s_( $R->op_add( undef, 'y' ) ),     'undefinedy', q<{{ u + 'y' }}> );
  is( s_( $R->op_add( undef, 1 ) ),       'NaN',   '{{ u + 1 }} (undefined->NaN)' );
};

subtest 'op_concat (~), sub/mul/div/mod/pow/floordiv' => sub {
  is( $R->op_concat( 1, 2 ),          '12',      '{{ 1 ~ 2 }}' );
  is( $R->op_concat( $R->op_concat( 'a', 3 ), true ), 'a3true', q<{{ 'a' ~ 3 ~ true }}> );
  is( $R->op_concat( $R->None, 'x' ), 'nullx',   q<{{ none ~ 'x' }}> );
  is( $R->op_concat( undef, 'x' ),    'undefinedx', q<{{ u ~ 'x' }}> );

  is( s_( $R->op_sub( '5', 1 ) ),   '4',   q<{{ '5' - 1 }}> );
  is( s_( $R->op_mul( '3', '2' ) ), '6',   q<{{ '3' * '2' }}> );
  is( s_( $R->op_mul( 'a', 2 ) ),   'NaN', q<{{ 'a' * 2 }}> );
  is( s_( $R->op_mul( 123456789, 987654321 ) ), '121932631112635260',
    'integer product forced into JS double arithmetic' );

  is( s_( $R->op_div( 10, 4 ) ), '2.5',      '{{ 10/4 }}' );
  is( s_( $R->op_div( 1, 0 ) ),  'Infinity', '{{ 1/0 }}' );
  is( s_( $R->op_div( -1, 0 ) ), '-Infinity','{{ -1/0 }}' );
  is( s_( $R->op_div( 0, 0 ) ),  'NaN',      '{{ 0/0 }}' );

  # F3: op_mul preserves IEEE -0 so a later division reads the sign of the zero
  is( s_( $R->op_mul( 0,  -1 ) ), '0', '{{ 0 * -1 }} renders 0 (but keeps -0 sign)' );
  is( s_( $R->op_div( 1,  $R->op_mul( 0,  -1 ) ) ), '-Infinity', '{{ 1/(0*-1) }}' );
  is( s_( $R->op_div( -1, $R->op_mul( 0,  -1 ) ) ), 'Infinity',  '{{ -1/(0*-1) }}' );
  is( s_( $R->op_div( 1,  $R->op_mul( 0,   1 ) ) ), 'Infinity',  '{{ 1/(0*1) }}' );
  is( s_( $R->op_div( 1,  $R->op_mul( -5,  0 ) ) ), '-Infinity', '{{ 1/(-5*0) }}' );

  is( s_( $R->op_mod( 7, 3 ) ),   '1',   '{{ 7 % 3 }}' );
  is( s_( $R->op_mod( -7, 3 ) ),  '-1',  '{{ -7 % 3 }} (sign of dividend)' );
  is( s_( $R->op_mod( 5.5, 2 ) ), '1.5', '{{ 5.5 % 2 }} (float mod)' );

  is( s_( $R->op_pow( 2, 0.5 ) ), '1.4142135623730951', '{{ 2 ** 0.5 }}' );
  is( s_( $R->op_pow( 2, 10 ) ),  '1024',               '{{ 2 ** 10 }}' );
  # compiler.js emits Math.pow: oracle 1 ** (1/0) and 1 ** ('a'*1) are NaN
  is( s_( $R->op_pow( 1, $R->op_div( 1, 0 ) ) ), 'NaN', '{{ 1 ** (1/0) }} (C pow gives 1)' );
  is( s_( $R->op_pow( 1, 'a' ) ),                'NaN', q<{{ 1 ** 'a' }}> );

  is( s_( $R->op_floordiv( 7, 2 ) ),  '3',  '{{ 7 // 2 }}' );
  is( s_( $R->op_floordiv( -7, 2 ) ), '-4', '{{ -7 // 2 }} (Math.floor, not trunc)' );

  is( s_( $R->op_neg(5) ),  '-5', '{{ -a }} a=5' );
  is( s_( $R->op_neg(0) ),  '0',  '{{ -0 }} -> 0' );
  is( s_( $R->op_pos('3') ),'3',  q<{{ +'3' }}> );
};

subtest 'comparisons: loose (==), strict (===), relational' => sub {
  is( s_( $R->op_eq( 1, '1' ) ),  'true',  q<{{ 1 == '1' }}> );
  is( s_( $R->op_seq( 1, '1' ) ), 'false', q<{{ 1 === '1' }}> );
  is( s_( $R->op_ne( 1, '1' ) ),  'false', q<{{ 1 != '1' }}> );
  is( s_( $R->op_sne( 1, '1' ) ), 'true',  q<{{ 1 !== '1' }}> );
  is( s_( $R->op_seq( 3, 3 ) ),   'true',  '{{ 3 === 3 }}' );

  is( s_( $R->op_eq( true, 1 ) ),  'true', '{{ true == 1 }}' );
  is( s_( $R->op_eq( false, 0 ) ), 'true', '{{ false == 0 }}' );
  is( s_( $R->op_eq( '', false ) ),'true', q<{{ '' == false }}> );

  # null / undefined loose-equality edges
  is( s_( $R->op_eq( $R->None, undef ) ),  'true',  '{{ n == u }} null==undefined' );
  is( s_( $R->op_eq( $R->None, $R->None ) ),'true', '{{ n == n }} null==null' );
  is( s_( $R->op_eq( $R->None, 0 ) ),      'false', '{{ n == 0 }} null==0' );

  is( s_( $R->op_lt( '10', '9' ) ), 'true',  "{{ '10' < '9' }} (string compare)" );
  is( s_( $R->op_lt( 10, 9 ) ),     'false', '{{ 10 < 9 }} (numeric)' );
  is( s_( $R->op_lt( '10', 9 ) ),   'false', "{{ '10' < 9 }} (mixed -> numeric)" );
  is( s_( $R->op_lt( 'a', 'b' ) ),  'true',  "{{ 'a' < 'b' }}" );
  is( s_( $R->op_lt( 'a', 1 ) ),    'false', "{{ 'a' < 1 }} (NaN -> false)" );
  is( s_( $R->op_lt( $R->None, 1 ) ),'true', '{{ n < 1 }} n=null (null->0)' );
  is( s_( $R->op_le( 2, 2 ) ),      'true',  '{{ 2 <= 2 }}' );
  is( s_( $R->op_ge( 3, 4 ) ),      'false', '{{ 3 >= 4 }}' );

  ok( is_bool( $R->op_eq( 1, 1 ) ), 'op_eq returns a boolean kind' );
};

subtest 'logical and/or/not and truthiness' => sub {
  # and/or return the operand, not a boolean
  is( $R->op_and( '0', 1 ), 1,   "{{ '0' and 1 }} -> 1 ('0' is truthy in JS)" );
  is( $R->op_or( 0, 'd' ),  'd', "{{ 0 or 'd' }} -> d" );
  is( s_( $R->op_not('0') ),  'false', q<{{ not '0' }}> );
  is( s_( $R->op_not(0) ),    'true',  '{{ not 0 }}' );
  is( s_( $R->op_not( [] ) ), 'false', '{{ not [] }} (empty array truthy)' );

  ok( !$R->_falsy('0'),      q<'0' is truthy (Perl disagrees)> );
  ok( !$R->_falsy( [] ),     'empty array truthy' );
  ok( !$R->_falsy( {} ),     'empty hash truthy' );
  ok( $R->_falsy(0),         '0 is falsy' );
  ok( $R->_falsy(''),        'empty string falsy' );
  ok( $R->_falsy(false),     'false is falsy' );
  ok( $R->_falsy(undef),     'undef (undefined) falsy' );
  ok( $R->_falsy( $R->None ),'None (null) falsy -- a ref, so Lib alone would miss it' );
  ok( !$R->_falsy( $R->SafeString->new('') ), 'empty SafeString truthy (an object)' );
};

#### undefined vs null distinction -- ADR 0006 (the substrate is/none/defined ride on)

subtest 'None sentinel vs undef (ADR 0006)' => sub {
  ok( $R->_is_none( $R->None ), 'None is the null sentinel' );
  ok( !$R->_is_none(undef),     'undef is not None' );
  ok( !$R->_is_none(0),         '0 is not None' );
  is( $R->None, $R->None, 'None is a single process-wide singleton' );

  # is defined / is none / is undefined build on: defined(None)=true, defined(undef)=false
  ok( defined( $R->None ), 'None is defined -> {{ n is defined }} true' );
  ok( !defined(undef),     'undef is not defined -> {{ u is defined }} false' );

  # rendering: both empty  ( [{{ n }}] / [{{ u }}] -> [] )
  is( $R->suppress_value( $R->None, 1 ), '', '{{ n }} renders empty' );
  is( $R->suppress_value( undef, 1 ),    '', '{{ u }} renders empty' );

  # member lookup on either -> undefined, no error ( {{ n.foo }} / {{ u.foo }} )
  is( $R->member_lookup( $R->None, 'foo' ), undef, '{{ n.foo }} -> undefined' );
  is( $R->member_lookup( undef, 'foo' ),    undef, '{{ u.foo }} -> undefined' );

  # throwOnUndefined fires for BOTH ( {{ a.b.c }} with throwOnUndefined )
  for my $pair ( [ undef, 'undefined' ], [ $R->None, 'null' ] ) {
    my $err;
    eval { $R->ensure_defined( $pair->[0], 0, 0 ); 1 } or $err = $@;
    ok( ref($err) && $err->isa('Text::Nunjucks::Lib::TemplateError'),
      'ensure_defined dies for ' . $pair->[1] );
    is( $err->message, 'attempted to output null or undefined value',
      'throwOnUndefined message (' . $pair->[1] . ')' );
  }
};

#### memberLookup emulated surface -- ADR 0008, oracle-grounded

subtest 'member_lookup: strings' => sub {
  is( $R->member_lookup( 'abc',  'length' ), 3, '{{ s.length }}' );
  is( $R->member_lookup( 'abcd', 'length' ), 4, q<{{ s['length'] }}> );
  is( $R->member_lookup( 'abc', 1 ),   'b', '{{ s[1] }}' );
  is( $R->member_lookup( 'abc', 9 ),   undef, '{{ s[9] }} out of range -> undefined' );
  is( _call( 'abc', 'toUpperCase' ),   'ABC', '{{ s.toUpperCase() }}' );
  is( _call( 'ABC', 'toLowerCase' ),   'abc', '{{ s.toLowerCase() }}' );
  is( _call( '  hi  ', 'trim' ),       'hi',  '{{ s.trim() }}' );
  is( _call( 'abcde', 'slice', 1, 3 ), 'bc',  '{{ s.slice(1,3) }}' );
  is( _call( 'abcde', 'slice', -2 ),   'de',  '{{ s.slice(-2) }}' );
  is( _call( 'abcde', 'substring', 1, 3 ), 'bc', '{{ s.substring(1,3) }}' );
  is( _call( 'banana', 'replace', 'a', 'X' ), 'bXnana', q<{{ s.replace('a','X') }} (first only)> );
  is( _call( 'abc', 'charAt', 1 ),     'b',  '{{ s.charAt(1) }}' );
  is( _call( 'abc', 'indexOf', 'b' ),  1,    q<{{ s.indexOf('b') }}> );
  is( _call( 'abc', 'concat', 'def' ), 'abcdef', q<{{ s.concat('def') }}> );
  is( join( '|', @{ _call( 'a,b,c', 'split', ',' ) } ), 'a|b|c', q<{{ s.split(',') }}> );
  is( join( '|', @{ _call( 'abc', 'split', '' ) } ),    'a|b|c', q<{{ s.split('') }}> );
};

subtest 'member_lookup: arrays (incl. in-place mutators)' => sub {
  is( $R->member_lookup( [ 1, 2, 3 ], 'length' ), 3, '{{ arr.length }}' );
  is( $R->member_lookup( [ 7, 8, 9 ], 0 ),        7, '{{ arr[0] }}' );
  is( $R->member_lookup( [ 7, 8, 9 ], '1' ),      8, q<{{ arr['1'] }}> );
  is( $R->member_lookup( [ 1, 2, 3 ], 9 ),    undef, '{{ arr[9] }} -> undefined' );

  is( _call( [ 1, 2, 3 ], 'join', '-' ), '1-2-3', q<{{ arr.join('-') }}> );
  is( _call( [ 1, 2, 3 ], 'join' ),      '1,2,3', '{{ arr.join() }} default sep' );
  is( _call( [ 1, undef, 3 ], 'join', '-' ), '1--3', 'join maps null/undef -> ""' );
  is( _call( [ 3, 1, 2 ], 'indexOf', 1 ),   1,  '{{ arr.indexOf(1) }}' );
  is( _call( [ 3, 1, 2 ], 'indexOf', '3' ), -1, q<{{ arr.indexOf('3') }} strict !== 3> );
  is( s_( _call( [ 1, 2, 3 ], 'slice', 1, 3 ) ),   '2,3',   '{{ arr.slice(1,3) }}' );
  # oracle: [1,2,3].slice(0, 'x') -> [], .slice('x') -> 1,2,3, .slice(0, 0/0) -> [],
  # .slice(1/0) -> [], .slice(0, 1/0) -> 1,2,3, .slice(-1.5) -> 3 -- ToIntegerOrInfinity (k55)
  my $inf = 9**9**9;
  is( s_( _call( [ 1, 2, 3 ], 'slice', 0, 'x' ) ),         '',      'a NaN end is 0' );
  is( s_( _call( [ 1, 2, 3 ], 'slice', 'x' ) ),            '1,2,3', 'a NaN start is 0' );
  is( s_( _call( [ 1, 2, 3 ], 'slice', 0, $inf / $inf ) ), '',      'NaN itself' );
  is( s_( _call( [ 1, 2, 3 ], 'slice', $inf ) ),           '',      'an infinite start' );
  is( s_( _call( [ 1, 2, 3 ], 'slice', 0, $inf ) ),        '1,2,3', 'an infinite end' );
  is( s_( _call( [ 1, 2, 3 ], 'slice', -1.5 ) ),           '3',     'a fraction truncates toward 0' );
  is( s_( _call( [ 1, 2, 3 ], 'concat', [ 4, 5 ] ) ), '1,2,3,4,5', '{{ arr.concat([4,5]) }}' );

  # mutators change the underlying arrayref in place and return JS values
  my $a = [ 3, 1, 2 ];
  is( _call( $a, 'push', 4 ), 4, '{{ arr.push(4) }} returns new length' );
  is( s_($a), '3,1,2,4', '... and mutates the array in place' );

  my $b = [ 3, 1, 2 ];
  is( _call( $b, 'pop' ), 2, 'pop returns last' );
  is( s_($b), '3,1', '... mutated' );

  my $c = [ 3, 1, 2 ];
  is( _call( $c, 'shift' ), 3, 'shift returns first' );
  is( s_($c), '1,2', '... mutated' );

  my $d = [ 3, 1, 2 ];
  is( _call( $d, 'unshift', 9 ), 4, 'unshift returns new length' );
  is( s_($d), '9,3,1,2', '... mutated' );

  my $e = [ 3, 1, 2 ];
  _call( $e, 'reverse' );
  is( s_($e), '2,1,3', 'reverse mutates in place' );

  my $f = [ 3, 1, 2, 10 ];
  _call( $f, 'sort' );
  is( s_($f), '1,10,2,3', 'sort() is a default STRING sort, in place' );

  # the member is Lib's js_array_sort (decision B, k17; its V8 replay is in
  # t/10-lib.t). Oracle: a macro m(a, b) giving a - b sorts [3, 1, 10, 2] to
  # 1,2,3,10 and returns the array; [nope, 'z', 'a'].sort() -> a,z, (length 3)
  my $g = [ 3, 1, 10, 2 ];
  my $m = sub { $_[0] - $_[1] };
  is( _call( $g, 'sort', $m ), $g, 'sort(comparefn) returns the array' );
  is( s_($g), '1,2,3,10', '... sorted by the comparefn, in place' );
  my $h = [ undef, 'z', 'a' ];
  _call( $h, 'sort' );
  is_deeply( $h, [ 'a', 'z', undef ], 'sort() puts undefined last' );
};

subtest 'member_lookup: numbers, hashes, blessed objects' => sub {
  is( _call( 3.14159, 'toFixed', 2 ), '3.14', '{{ n.toFixed(2) }}' );
  is( _call( 3,       'toFixed', 2 ), '3.00', '{{ n.toFixed(2) }} n=3' );
  is( _call( 3.7,     'toFixed' ),    '4',    '{{ n.toFixed() }} default 0 digits' );

  is( $R->member_lookup( { a => 42 }, 'a' ),  42,    '{{ o.a }}' );
  is( $R->member_lookup( { a => 42 }, 'z' ),  undef, '{{ o.z }} missing -> undefined' );
  is( $R->member_lookup( $R->member_lookup( { a => { b => 7 } }, 'a' ), 'b' ),
    7, '{{ a.b }} nested' );

  # ADR 0016: blessed-object member_lookup is the PROPERTY seam -- returns
  # the value (an accessor result / attribute read), not a coderef. The
  # method-call seam is member_lookup_method (tested below). Until ADR 0009
  # this would also need a value-only accessor; the test obj below has greet
  # that returns a string, so member_lookup produces the string directly.
  my $obj = TN_Test_Obj->new('world');
  is( $R->member_lookup( $obj, 'nonesuch' ), undef, 'missing member -> undefined' );
  is( $R->member_lookup( $obj, 'name' ), 'world', 'name attribute readable' );
};

# ADR 0016: the method-call seam. FunCall over a LookupVal (e.g. obj.foo())
# resolves its callable through here, not through member_lookup. Hash/array
# values are returned only if they are coderefs (matches upstream's
# "not a function" TypeError for plain-object calls).
subtest 'member_lookup_method: blessed objects bind the owner (ADR 0016)' => sub {
  my $obj = TN_Test_Obj->new('world');
  my $m   = $R->member_lookup_method( $obj, 'greet' );
  ok( ref($m) eq 'CODE', 'method member -> a bound closure' );
  is( $R->call_wrap( $m, 'obj.greet', undef, [] ), 'hi world',
    'member call runs $obj->greet, owner bound' );
  is( $R->member_lookup_method( $obj, 'nonesuch' ), undef,
    'missing method -> undefined' );

  # plain hash: callable value -> bound; non-callable -> undef (upstream
  # `obj.foo()` over a plain hash with no `foo` member dies "not a function").
  is( $R->member_lookup_method( { greet => sub { 'coderef-value' } }, 'greet' )->(),
    'coderef-value', 'plain-hash coderef member returned as-is' );
  is( $R->member_lookup_method( { name => 'world' }, 'greet' ), undef,
    'plain-hash non-callable member -> undef (call_wrap dies with upstream text)' );
};

subtest 'member_lookup: SafeString is a String OBJECT, not a primitive (F1)' => sub {
  # {% set s = 'abc'|safe %} ... a SafeString has length + methods but NO exotic
  # index access ({{ s[0] }} and {{ s['0'] }} render '', unlike a plain string).
  my $ss = $R->SafeString->new('abcde');
  is( $R->member_lookup( $ss, 0 ),   undef, '{{ s[0] }} on SafeString -> undefined' );
  is( $R->member_lookup( $ss, '0' ), undef, "{{ s['0'] }} on SafeString -> undefined" );
  is( $R->member_lookup( $ss, 'length' ), 5, '{{ s.length }} on SafeString still works' );
  is( _call( $ss, 'toUpperCase' ), 'ABCDE', 'SafeString.toUpperCase() works' );
  is( _call( $ss, 'charAt', 1 ),   'b',     'SafeString.charAt(1) works' );
  is( _call( $ss, 'slice', 1, 3 ), 'bc',    'SafeString.slice(1,3) works' );
  # a plain string still HAS index access
  is( $R->member_lookup( 'abc', 0 ), 'a', '{{ s[0] }} on a plain string -> char' );
};

# The corpus case "case mapping does not die on a lone surrogate" cannot see a
# warning; Perl's uc/lc warn on a surrogate ("returns its argument for UTF-16
# surrogate"), JS maps it to itself silently (node: '\ud83d'.toUpperCase()).
subtest 'member_lookup: case mapping a lone surrogate does not warn (ADR 0012)' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is( _call( "\x{D83D}", 'toUpperCase' ), "\x{D83D}", 'toUpperCase maps a lone high surrogate to itself' );
  is( _call( "\x{DE00}", 'toLowerCase' ), "\x{DE00}", 'toLowerCase maps a lone low surrogate to itself' );
  is_deeply( \@warnings, [], 'no warning' );
};

# {% for c in s %} indexes s through _for_code_units: the code units of a
# primitive string, split once (ADR 0012); the loop's results are pinned by the
# corpus, this pins what passes through untouched.
subtest '_for_code_units: only a primitive string becomes its code units' => sub {
  is_deeply( $R->_for_code_units("\x{1F600}a"), [ "\x{D83D}", "\x{DE00}", 'a' ], 'string -> code units' );
  my $arr = [ 1, 2 ];
  is( $R->_for_code_units($arr), $arr, 'an array passes through as itself' );
  my $ss = $R->SafeString->new('ab');
  is( $R->_for_code_units($ss), $ss, 'a SafeString (a String object) passes through' );
  is( $R->_for_code_units(5), 5, 'a number passes through' );
};

#### callWrap / kwargs / macros -- ADR 0009

subtest 'callWrap error text and dispatch' => sub {
  # {{ s.nope() }} : the compiler passes a name string; callWrap interpolates it
  my $err;
  eval { $R->call_wrap( undef, 's["nope"]', undef, [] ); 1 } or $err = $@;
  ok( ref($err) && $err->isa('Text::Nunjucks::Lib::Error'), 'undefined callee dies with an Error' );
  is( $err->message, 'Unable to call `s["nope"]`, which is undefined or falsey',
    'exact upstream text for undefined/falsey callee' );

  # {{ s.length() }} : length is a number, not callable
  undef $err;
  eval { $R->call_wrap( 3, 's["length"]', undef, [] ); 1 } or $err = $@;
  is( $err->message, 'Unable to call `s["length"]`, which is not a function',
    'exact upstream text for non-function callee' );

  # bare context coderef: called with args, no `this` (ADR 0009 divergence)
  my @seen;
  my $code = sub { @seen = @_; return 'r=' . join( ',', @_ ) };
  is( $R->call_wrap( $code, 'fn', 'CTX', [ 1, 2 ] ), 'r=1,2', 'bare coderef called with args' );
  is_deeply( \@seen, [ 1, 2 ], 'no Context prepended as invocant' );
};

subtest 'makeKeywordArgs / isKeywordArgs / getKeywordArgs / numArgs' => sub {
  my $kw = $R->make_keyword_args( { a => 1, b => 2 } );
  ok( $R->is_keyword_args($kw), 'blessed KwArgs is recognised' );
  ok( !$R->is_keyword_args( { a => 1 } ), 'a plain hashref is not KwArgs' );
  ok( !$R->is_keyword_args(undef),        'undef is not KwArgs' );
  is( $kw->{a}, 1, 'KwArgs hash keys are the keyword values (no __keywords key)' );

  is_deeply( $R->get_keyword_args( [ 1, 2, $kw ] ), $kw, 'trailing KwArgs returned' );
  is_deeply( $R->get_keyword_args( [ 1, 2 ] ),      {},  'no trailing KwArgs -> {}' );
  is_deeply( $R->get_keyword_args( [] ),            {},  'empty args -> {}' );

  is( $R->num_args( [] ),            0, 'numArgs [] = 0' );
  is( $R->num_args( [ 1, 2 ] ),      2, 'numArgs of plain args' );
  is( $R->num_args( [ 1, 2, $kw ] ), 2, 'numArgs excludes trailing KwArgs' );
};

subtest 'makeMacro: positional <-> keyword remapping' => sub {
  # equal arity: args passed straight through
  {
    my @got;
    my $macro = $R->make_macro( [qw( a b )], [], sub { @got = @_; '' } );
    $macro->( 1, 2 );
    is_deeply( \@got, [ 1, 2 ], 'argCount == argNames: (a, b)' );
  }
  # extra positional -> folded into kwargs by kwargNames position
  {
    my @got;
    my $macro = $R->make_macro( ['a'], ['b'], sub { @got = @_; '' } );
    $macro->( 1, 2 );
    is( $got[0], 1, 'first positional kept' );
    # getKeywordArgs returned a plain {} here (no trailing __keywords), matching
    # upstream: the overflow bag is an ordinary hashref, not a marked KwArgs.
    is( ref( $got[1] ), 'HASH', 'overflow collected into a trailing kwargs hashref' );
    is( $got[1]{b}, 2, 'extra positional placed under kwargName b' );
  }
  # too few positional -> filled from kwargs passed by name
  {
    my @got;
    my $macro = $R->make_macro( [qw( a b )], [], sub { @got = @_; '' } );
    $macro->( 1, $R->make_keyword_args( { b => 2 } ) );
    is( $got[0], 1, 'positional a' );
    is( $got[1], 2, 'b pulled from kwargs by name' );
    is_deeply( $got[2], {}, 'consumed kwarg removed, empty kwargs trail' );
  }
};

#### ported runtime.js structural pieces

subtest 'Frame: set / get / lookup / resolve / push / pop' => sub {
  my $f = $R->Frame->new;
  is_deeply( $f->variables, {}, 'fresh variables bag' );
  is( $f->parent,    undef, 'no parent' );
  is( $f->top_level, 0,     'topLevel starts false' );

  $f->set( 'a', 1 );
  is( $f->get('a'),    1, 'get returns a set value' );
  is( $f->lookup('a'), 1, 'lookup returns a set value' );
  is( $f->get('missing'),    $R->None, 'get missing -> null (None)' );
  is( $f->lookup('missing'), undef,    'lookup missing -> undefined (undef)' );

  $f->set( 'x.y.z', 5 );
  is( $f->variables->{x}{y}{z}, 5, 'dotted set builds nested structure' );

  my $child = $f->push;
  is( $child->parent, $f, 'push creates a child with parent' );
  is( $child->lookup('a'), 1, 'child reads through to parent (lookup)' );
  is( $child->pop, $f, 'pop returns the parent' );

  is( $f->resolve('a'), $f, 'resolve finds the owning frame' );
  is( $child->resolve('a'), $f, 'resolve walks up to the owner' );

  # resolveUp writes to the owning ancestor
  $child->set( 'a', 99, 1 );
  is( $f->get('a'), 99, 'set(resolveUp) writes to the ancestor that owns it' );

  # isolate_writes blocks the upward write, forcing a local one
  my $iso = $f->push(1);
  $iso->set( 'a', 7, 1 );
  is( $iso->variables->{a}, 7,  'isolateWrites keeps the write local' );
  is( $f->get('a'),         99, '... parent value untouched' );
};

subtest 'suppress_value' => sub {
  is( $R->suppress_value( '<b>', 1 ), '&lt;b&gt;', 'autoescape on escapes' );
  is( $R->suppress_value( '<b>', 0 ), '<b>',       'autoescape off leaves raw' );
  is( $R->suppress_value( $R->None, 1 ), '', 'null -> empty' );
  is( $R->suppress_value( undef, 1 ),    '', 'undefined -> empty' );
  my $safe = $R->SafeString->new('<b>');
  is( $R->suppress_value( $safe, 1 ), $safe, 'SafeString not escaped even with autoescape' );
  is( "$safe", '<b>', 'SafeString stringifies to its value' );
};

subtest 'SafeString / markSafe / copySafeness' => sub {
  my $ss = $R->SafeString->new('hi');
  ok( $R->_is_safe_string($ss), 'SafeString recognised' );
  is( $ss->val,    'hi', 'val' );
  is( $ss->length, 2,    'length' );
  # this.length = val.length, in UTF-16 code units (ADR 0012; oracle: 'héllo😀'|safe has length 7)
  is( $R->SafeString->new("h\x{E9}llo\x{1F600}")->length, 7, 'length counts UTF-16 code units' );
  is( "$ss",       'hi', 'stringification overload' );
  # non-string passes through unchanged (JS: new SafeString(5) === 5)
  is( $R->SafeString->new(5), 5, 'SafeString(non-string) returns the value' );

  my $m = $R->mark_safe('<x>');
  ok( $R->_is_safe_string($m), 'mark_safe on a string -> SafeString' );
  is( $R->mark_safe(5), 5, 'mark_safe on a non-string/non-fn -> value' );
  my $wrapped = $R->mark_safe( sub { 'raw<>' } );
  ok( $R->_is_safe_string( $wrapped->() ), 'mark_safe on a fn wraps a string return' );

  # copySafeness: SafeString dest -> SafeString(target); else target.toString()
  ok( $R->_is_safe_string( $R->copy_safeness( $ss, 'new' ) ), 'safe dest -> safe result' );
  my $plain = $R->copy_safeness( 'plain', 'new' );
  ok( !$R->_is_safe_string($plain), 'plain dest -> plain result' );
  is( $plain, 'new', 'plain result is the target string' );
  # target.toString() -- oracle: 5|string -> 5, undefined|string and none|string throw
  is( $R->copy_safeness( 5, 5 ), '5', 'a number target -> its ToString' );
  my $err = do { local $@; eval { $R->copy_safeness( undef, undef ); 1 } ? undef : $@ };
  is( $err && $err->name . ': ' . $err->message,
    q{TypeError: Cannot read properties of undefined (reading 'toString')}, 'an undefined target throws' );
  $err = do { local $@; eval { $R->copy_safeness( $R->None, $R->None ); 1 } ? undef : $@ };
  is( $err && $err->name . ': ' . $err->message,
    q{TypeError: Cannot read properties of null (reading 'toString')}, 'a null target throws' );
};

subtest 'ensure_defined / handle_error / context_or_frame_lookup' => sub {
  is( $R->ensure_defined( 0, 0, 0 ),  0,  'ensure_defined passes 0 through' );
  is( $R->ensure_defined( '', 0, 0 ), '', 'ensure_defined passes empty string' );

  # handle_error wraps a bare error; leaves an already-positioned one alone
  my $wrapped = $R->handle_error( 'boom', 3, 4 );
  ok( $wrapped->isa('Text::Nunjucks::Lib::TemplateError'), 'bare error -> TemplateError' );
  my $te = Text::Nunjucks::Lib::TemplateError->new( 'x', 1, 2 );
  is( $R->handle_error( $te, 9, 9 ), $te, 'already-positioned error returned as-is' );

  # contextOrFrameLookup: frame wins if defined, else context
  my $frame = $R->Frame->new;
  $frame->set( 'x', 'from_frame' );
  my $ctx = TN_Test_Ctx->new( { x => 'from_ctx', y => 'from_ctx' } );
  is( $R->context_or_frame_lookup( $ctx, $frame, 'x' ), 'from_frame', 'frame value preferred' );
  is( $R->context_or_frame_lookup( $ctx, $frame, 'y' ), 'from_ctx',   'falls back to context' );
};

subtest 'asyncEach / asyncAll / fromIterator (CPS, ADR 0003 -- sync here)' => sub {
  # asyncAll over an array (dimen 1) joins outputs in order
  my $res;
  $R->async_all(
    [ 1, 2, 3 ], 1,
    sub { my ( $item, $i, $len, $done ) = @_; $done->( $i, "<$item>" ) },
    sub { ( undef, $res ) = @_ },
  );
  is( $res, '<1><2><3>', 'asyncAll array collects outputs' );

  # asyncAll over an empty array -> ''
  undef $res;
  $R->async_all( [], 1, sub { }, sub { ( undef, $res ) = @_ } );
  is( $res, '', 'asyncAll empty array -> empty' );

  # asyncAll over an object
  undef $res;
  $R->async_all(
    { a => 10 }, 1,
    sub { my ( $k, $v, $i, $len, $done ) = @_; $done->( $i, "$k=$v" ) },
    sub { ( undef, $res ) = @_ },
  );
  is( $res, 'a=10', 'asyncAll object collects key=val' );

  # asyncEach array (dimen 1)
  my @seen;
  $R->async_each(
    [ 'p', 'q' ], 1,
    sub { my ( $item, $i, $len, $next ) = @_; push @seen, "$i:$item:$len"; $next->() },
    sub { push @seen, 'done' },
  );
  is_deeply( \@seen, [ '0:p:2', '1:q:2', 'done' ], 'asyncEach array iterates then cb' );

  # asyncEach object
  @seen = ();
  $R->async_each(
    { k => 'v' }, 1,
    sub { my ( $key, $val, $i, $len, $next ) = @_; push @seen, "$key=$val"; $next->() },
    sub { push @seen, 'done' },
  );
  is_deeply( \@seen, [ 'k=v', 'done' ], 'asyncEach object iterates then cb' );

  # fromIterator: identity for the value kinds Perl models
  my $arr = [ 1, 2 ];
  is( $R->from_iterator($arr), $arr,     'array passes through' );
  is( $R->from_iterator('s'),  's',      'scalar passes through' );
  is( $R->from_iterator(undef), undef,   'undef passes through' );
  is( $R->from_iterator( $R->None ), $R->None, 'None passes through' );
};

subtest 'async loops over null / falsy iterables (F2)' => sub {
  # {% asyncEach/asyncAll x in n %}...{% end %} with n = null/undefined/0/'' ->
  # empty output, never a crash on Lib->keys deref (JS: keys(arr || {})).
  for my $case ( [ $R->None, 'null' ], [ undef, 'undefined' ], [ 0, 'zero' ], [ '', 'empty string' ] ) {
    my ( $val, $label ) = @$case;

    my $out;
    my $ok = eval {
      $R->async_all( $val, 1, sub { }, sub { ( undef, $out ) = @_ } );
      1;
    };
    ok( $ok, "async_all over $label does not crash" );
    is( $out, '', "async_all over $label -> empty" );

    my @seen;
    $ok = eval {
      $R->async_each( $val, 1, sub { push @seen, 'iter' }, sub { push @seen, 'done' } );
      1;
    };
    ok( $ok, "async_each over $label does not crash" );
    is_deeply( \@seen, ['done'], "async_each over $label -> empty loop, cb fires" );
  }

  # a real object still iterates
  my $out;
  $R->async_all( { a => 1 }, 1,
    sub { my ( $k, $v, $i, $l, $d ) = @_; $d->( $i, "$k=$v" ) },
    sub { ( undef, $out ) = @_ } );
  is( $out, 'a=1', 'async_all over a non-empty object still iterates' );
};

subtest 'async loops over Hash::Ordered values (k41)' => sub {
  # ADR 0011: template dict literals and engine-built objects are Hash::Ordered.
  # Lib::async_for reads via the Hash::Ordered branch; Runtime::async_all reads
  # via member_lookup (which already handles Hash::Ordered). A Hash::Ordered
  # caller arg must not die "Not a HASH reference" on either loop.
  my $items = Hash::Ordered->new( foo => 1, bar => 2, baz => 3 );

  # async_all collects outputs in insertion order
  my $out;
  $R->async_all(
    $items, 1,
    sub { my ( $k, $v, $i, $l, $d ) = @_; $d->( $i, "$k=$v" ) },
    sub { ( undef, $out ) = @_ },
  );
  is( $out, 'foo=1bar=2baz=3', 'async_all over Hash::Ordered collects in insertion order' );

  # async_each iterates the same way
  my @seen;
  $R->async_each(
    $items, 1,
    sub {
      my ( $k, $v, $i, $l, $next ) = @_;
      push @seen, "$i:$k=$v";
      $next->();
    },
    sub { push @seen, 'done' },
  );
  is_deeply(
    \@seen,
    [ '0:foo=1', '1:bar=2', '2:baz=3', 'done' ],
    'async_each over Hash::Ordered iterates in insertion order',
  );
};

subtest 'container ToString (_js_to_string) -- mechanism in Runtime' => sub {
  is( $R->_js_to_string( [ 3, 1, 2 ] ),   '3,1,2',           '{{ [3,1,2] }}' );
  is( $R->_js_to_string( {} ),            '[object Object]', '{{ {} }}' );
  is( $R->_js_to_string( [ $R->None, 1 ] ), ',1',            '{{ [none, 1] }}' );
  is( $R->_js_to_string( [ true, false ] ), 'true,false',    '{{ [true, false] }}' );
  is( $R->_js_to_string( [ 1, [ 2, 3 ] ] ), '1,2,3',         '{{ [1, [2,3]] }}' );
  is( $R->_js_to_string(true),  'true',  'ToString(true)' );
  is( $R->_js_to_string(false), 'false', 'ToString(false)' );
  is( $R->_js_to_string( 1 / 3 ), '0.3333333333333333', 'ToString routes numbers through Lib' );
};

subtest 're-exported lib helpers (isArray / keys / inOperator)' => sub {
  ok( $R->is_array( [ 1, 2 ] ), 'is_array delegates to Lib' );
  ok( !$R->is_array( {} ),      'is_array false on hash' );
  is_deeply( [ sort @{ $R->keys( { a => 1, b => 2 } ) } ], [qw( a b )], 'keys delegates to Lib' );
  ok( $R->in_operator( 'b', 'abc' ),  'in_operator: substring' );
  ok( $R->in_operator( 1, [ 1, 2 ] ), 'in_operator: array membership' );
};

# ADR 0013 / k46: RegExp.prototype.exec/test with the JS g/y flags honour
# lastIndex on the Regex object (sticky matches anchored at lastIndex; global
# advances lastIndex past the match on success and resets to 0 on failure;
# non-g/non-y regexes leave lastIndex alone). These tests pin the behaviour
# directly on the Runtime methods, complementing the end-to-end corpus cases
# in t/corpus/render-compiler.json (k46-tagged).
subtest 'Regex: JS g/y flag semantics honour lastIndex (k46, ADR 0013)' => sub {
  # --- sticky /y -------------------------------------------------------
  {
    my $r = $R->make_regex( 'x', 'y' );

    # default lastIndex is 0 (JS initial value)
    is( $r->lastIndex, 0, 'sticky: fresh regex lastIndex = 0' );

    # test: match advances lastIndex by the match length
    ok( $r->test('xyx'), 'sticky: test match at pos 0' );
    is( $r->lastIndex, 1, 'sticky: lastIndex advanced to 1 after match' );

    # reset and try a no-match
    $r->lastIndex(0);
    ok( !$r->test('yxy'), 'sticky: test no-match at pos 0' );
    is( $r->lastIndex, 0, 'sticky: lastIndex resets to 0 on no-match' );

    # anchored: fails when pos is past the only match
    $r->lastIndex(0);
    ok( $r->test('xyx'), 'sticky: pos 0 match' );
    is( $r->lastIndex, 1, 'sticky: lastIndex now 1' );
    ok( !$r->test('xyx'), 'sticky: pos 1 anchored fails (only one x at pos 0)' );
    is( $r->lastIndex, 0, 'sticky: lastIndex reset to 0 on anchored failure' );

    # exec: sticky no-match returns undef
    $r->lastIndex(0);
    is( $r->exec('yxy'), undef, 'sticky: exec returns undef on no-match' );
    is( $r->lastIndex, 0, 'sticky: exec no-match leaves lastIndex at 0' );

    # exec: sticky match returns the array. Pattern uses a capture group
    # so we do not entangle with the no-capture-groups list-context quirk
    # tracked separately as #48.
    $r->lastIndex(0);
    my $rs = $R->make_regex( '(x)', 'y' );
    my $m = $rs->exec('xyx');
    is_deeply( $m, [ 'x', 'x' ], 'sticky: exec returns [full_match, cap] at pos 0' );
    is( $rs->lastIndex, 1, 'sticky: exec advanced lastIndex' );
  }

  # --- global /g -------------------------------------------------------
  {
    my $r = $R->make_regex( '(\d)', 'g' );
    is( $r->lastIndex, 0, 'global: fresh regex lastIndex = 0' );

    # stateful iteration (matches what JS /g exec does)
    my $e1 = $r->exec('1 2 3');
    is_deeply( $e1, [ '1', '1' ], 'global: exec 1 returns [full, cap]' );
    is( $r->lastIndex, 1, 'global: lastIndex = 1 after first match' );

    my $e2 = $r->exec('1 2 3');
    is_deeply( $e2, [ '2', '2' ], 'global: exec 2 advances to next match' );
    is( $r->lastIndex, 3, 'global: lastIndex = 3 after second match' );

    my $e3 = $r->exec('1 2 3');
    is_deeply( $e3, [ '3', '3' ], 'global: exec 3 advances to next match' );
    is( $r->lastIndex, 5, 'global: lastIndex = 5 after third match' );

    # next call: nothing past pos 5, so no match; JS resets to 0
    my $e4 = $r->exec('1 2 3');
    is( $e4, undef, 'global: exec past end returns undef' );
    is( $r->lastIndex, 0, 'global: lastIndex reset to 0 on no-match' );

    # test also tracks lastIndex and resets on no-match
    my $t = $R->make_regex( 'x', 'g' );
    ok( $t->test('axb'), 'global: test match' );
    is( $t->lastIndex, 2, 'global: test advances lastIndex' );
    ok( !$t->test('abc'), 'global: test no-match at advanced pos' );
    is( $t->lastIndex, 0, 'global: test resets lastIndex on no-match' );
  }

  # --- neither flag: lastIndex is left alone ---------------------------
  {
    my $r = $R->make_regex( 'x', '' );
    $r->lastIndex(7);                                  # deliberately set
    ok( $r->test('xyx'), 'plain: test match (stateless)' );
    is( $r->lastIndex, 7, 'plain: lastIndex unchanged on match' );

    $r->lastIndex(7);
    ok( !$r->test('abc'), 'plain: test no-match (stateless)' );
    is( $r->lastIndex, 7, 'plain: lastIndex unchanged on no-match' );

    $r->lastIndex(7);
    # Pattern with a capture group to avoid the no-capture-groups
    # list-context quirk tracked separately as #48.
    my $rp = $R->make_regex( '(x)', '' );
    $rp->lastIndex(7);
    my $m = $rp->exec('xyx');
    is_deeply( $m, [ 'x', 'x' ], 'plain: exec returns [full, cap] (stateless)' );
    is( $rp->lastIndex, 7, 'plain: exec leaves lastIndex unchanged' );

    $r->lastIndex(7);
    is( $r->exec('abc'), undef, 'plain: exec undef on no-match (stateless)' );
    is( $r->lastIndex, 7, 'plain: exec no-match leaves lastIndex unchanged' );
  }

  # --- lastIndex is template-visible via member_lookup -----------------
  {
    my $r = $R->make_regex( 'x', 'g' );
    is( $R->member_lookup( $r, 'lastIndex' ),
      0, 'member_lookup exposes lastIndex (default 0)' );
    $r->lastIndex(5);
    is( $R->member_lookup( $r, 'lastIndex' ),
      5, 'member_lookup reflects updated lastIndex' );
  }
};

# k48: Perl 5.40 list-context =~ against a qr// with no capture groups returns
# the boolean match result instead of an empty list. JS RegExp.prototype.exec
# always returns [full, ...captures] for any pattern. exec() must drop the
# boolean so the result has JS's shape: [full] for no-groups, [full, c1, c2, ...]
# otherwise. Pinned at the unit level to complement the corpus coverage (which
# catches it through the full render path).
subtest 'Regex::exec drops the boolean for no-capture-group patterns (k48)' => sub {
  # --- stateless match ------------------------------------------------
  {
    my $r = $R->make_regex( 'x', '' );
    is_deeply( $r->exec('xx'), ['x'],
      'stateless: no groups -> [full] (no boolean)' );

    my $m = $r->exec('xx');
    is( $m->[0], 'x', 'stateless: m[0] is the full match' );
    is( $m->[1], undef, 'stateless: m[1] is undef (undefined, not "true")' );
    is( scalar @$m, 1, 'stateless: array length is 1' );

    is( $r->exec('yy'), undef, 'stateless: no-match still returns undef' );
  }

  # --- capture groups still work (the k43 contract is preserved) ------
  {
    my $r = $R->make_regex( '(.)(.)', '' );
    is_deeply( $r->exec('ab'), [ 'ab', 'a', 'b' ],
      'capture groups: [full, c1, c2] (k43 shape)' );

    my $m = $r->exec('ab');
    is( $m->[0], 'ab', 'capture groups: m[0] is the full match' );
    is( $m->[1], 'a',  'capture groups: m[1] is the first capture' );
    is( $m->[2], 'b',  'capture groups: m[2] is the second capture' );
  }

  # --- mixed: non-capturing + capturing -------------------------------
  {
    my $r = $R->make_regex( '(?:x)(y)', '' );
    is_deeply( $r->exec('xy'), [ 'xy', 'y' ],
      '(?:x)(y): (?:...) does not capture, only (y) does' );
  }

  # --- named capture group --------------------------------------------
  {
    my $r = $R->make_regex( '(?<name>\d+)', '' );
    is_deeply( $r->exec('42'), [ '42', '42' ],
      '(?<name>...) is a named capture and counts' );
  }

  # --- global /g, no groups -------------------------------------------
  {
    my $r = $R->make_regex( 'x', 'g' );
    is_deeply( $r->exec('xx'), ['x'],
      'global: no groups -> [full] (no boolean)' );
    is( $r->lastIndex, 1, 'global: lastIndex still advances to 1' );
    is_deeply( $r->exec('xx'), ['x'],
      'global: second exec -> [full] (no boolean)' );
    is( $r->lastIndex, 2, 'global: lastIndex now 2' );
    is( $r->exec('xx'), undef, 'global: third exec past end -> undef' );
  }

  # --- sticky /y, no groups -------------------------------------------
  {
    my $r = $R->make_regex( 'x', 'y' );
    is_deeply( $r->exec('xyx'), ['x'],
      'sticky: no groups -> [full] (no boolean)' );
    is( $r->lastIndex, 1, 'sticky: lastIndex advances' );
    is( $r->exec('xyx'), undef,
      'sticky: at advanced pos, anchored no-match -> undef' );
    is( $r->lastIndex, 0, 'sticky: lastIndex reset to 0 on no-match' );
  }

  # --- the _captures_count / _group_names classifier on edge bodies ---
  {
    # one entry per capture group in source order: undef numbered, else the name
    my $g = sub { $R->Regex->_capture_groups(shift) };
    is_deeply( $g->('x'),                 [],                     'plain body -> no group' );
    is_deeply( $g->('(.)(.)'),            [ undef, undef ],       '(.)(.) -> 2' );
    is_deeply( $g->('(?:x)'),             [],                     '(?:x) -> 0 (non-capturing)' );
    is_deeply( $g->('(?=x)x'),            [],                     '(?=x)x -> 0 (lookahead)' );
    is_deeply( $g->('(?!x)x'),            [],                     '(?!x)x -> 0 (neg lookahead)' );
    is_deeply( $g->('(?<=x)x'),           [],                     '(?<=x)x -> 0 (lookbehind)' );
    is_deeply( $g->('(?<!x)x'),           [],                     '(?<!x)x -> 0 (neg lookbehind)' );
    is_deeply( $g->('(?<name>\d+)'),      ['name'],               '(?<name>\\d+) -> 1 (named capture)' );
    is_deeply( $g->('[a](b)'),            [undef],                '[a](b) -> 1 (char class ignored)' );
    is_deeply( $g->('\(x\)'),             [],                     '\\(x\\) -> 0 (escaped parens)' );
    is_deeply( $g->('(?#c)x'),            [],                     '(?#c)x -> 0 (comment group)' );
    is_deeply( $g->('(a)(?:b)(c)'),       [ undef, undef ],       '(a)(?:b)(c) -> 2' );
    is_deeply( $g->('(?<z>a)(b)(?<b>c)'), [ 'z', undef, 'b' ],    'named and numbered, in source order' );
    is_deeply( $g->('[(?<q>](?<b>b)'),    ['b'],                  'no named group inside a class' );

    # _group_names: the named ones, each once, in source order
    is_deeply( $R->make_regex( '(?<z>a)(b)(?<b>c)', '' )->_group_names, [ 'z', 'b' ], '_group_names in source order' );
    is_deeply( $R->make_regex( '(?<n>a)|(?<m>c)|(?<n>b)', '' )->_group_names, [ 'n', 'm' ],
      '_group_names: a duplicate name keeps its first place' );
    is( $R->make_regex( '(?<n>a)|(?<m>c)|(?<n>b)', '' )->_captures_count, 3, '... and still counts as a group' );
  }
};

#### native method calls the built-in filters make (ADR 0016 / ADR 0010)

sub _type_error {
  my ($code) = @_;
  my $err = eval { $code->(); undef } // $@;
  return ref($err) ? $err->name . ': ' . $err->message : "no error: $err";
}

subtest 'js_method_call / js_string_this: the member call and its V8 TypeError' => sub {
  # oracle: 5|lower, undefined|trim, null|trim, {a:1}|lower, 'Ab'|lower
  is( $R->js_method_call( 'Ab', 'str', 'toLowerCase' ), 'ab', 'a string method' );
  is( $R->js_method_call( $R->SafeString->new('Ab'), 'str', 'toLowerCase' ), 'ab', 'a SafeString works off its value' );
  is( s_( $R->js_method_call( [ 1, 2 ], 'input', 'lastIndexOf', ' ', 3 ) ), '-1', 'an array method' );
  is( _type_error( sub { $R->js_method_call( 5, 'str', 'toLowerCase' ) } ),
    'TypeError: str.toLowerCase is not a function', 'a number has no toLowerCase' );
  is( _type_error( sub { $R->js_method_call( Hash::Ordered->new( a => 1 ), 'str', 'toLowerCase' ) } ),
    'TypeError: str.toLowerCase is not a function', 'nor a dict literal' );
  is( _type_error( sub { $R->js_method_call( undef, 'str', 'split', ' ' ) } ),
    q{TypeError: Cannot read properties of undefined (reading 'split')}, 'undefined: the read throws' );
  is( _type_error( sub { $R->js_method_call( $R->None, 'str', 'split', ' ' ) } ),
    q{TypeError: Cannot read properties of null (reading 'split')}, 'null: the read throws' );

  is( $R->js_string_this( 'a', 'str', 'replace' ), 'a', 'js_string_this: a string is itself' );
  is( $R->js_string_this( $R->SafeString->new('<a>'), 'str', 'replace' ), '<a>', 'a SafeString is its value' );
  is( _type_error( sub { $R->js_string_this( builtin::false, 'str', 'replace' ) } ),
    'TypeError: str.replace is not a function', 'false is no string (nl2br(false))' );
  is( _type_error( sub { $R->js_string_this( undef, 'str', 'replace' ) } ),
    q{TypeError: Cannot read properties of undefined (reading 'replace')}, 'undefined (trim(undefined))' );
};

subtest 'member_lookup_method on a dict literal (Hash::Ordered)' => sub {
  # oracle: {{ {a:1}.foo() }} -> Unable to call `--expression--["foo"]`, which is undefined or falsey
  my $fn = sub { 'called' };
  my $h  = Hash::Ordered->new( a => 1, f => $fn );
  is( $R->member_lookup_method( $h, 'f' ), $fn, 'a callable member comes back' );
  my $got = eval { $R->member_lookup_method( $h, 'foo' ) };
  is( $@, '', 'a missing member does not die' );
  is( $got, undef, '... and is undefined' );
};

subtest 'Array lastIndexOf' => sub {
  # oracle: [1,2,1].lastIndexOf(1) (1, 1) (1, -1) (1, -2) (1, -9) (1, 9) (1, 'x')
  # (1, -1/0) (1, 1/0) (1, 1.9), [].lastIndexOf(undefined), [1,'1'].lastIndexOf('1')
  # -> 2|0|2|0|-1|2|0|-1|2|0, -1, 1
  my @got = map { s_( _call( [ 1, 2, 1 ], 'lastIndexOf', 1, @$_ ) ) }
    [], [1], [-1], [-2], [-9], [9], ['x'], [ -9**9**9 ], [ 9**9**9 ], [1.9];
  is( join( '|', @got ), '2|0|2|0|-1|2|0|-1|2|0', 'fromIndex: absent, in range, negative, out of range, NaN, infinite, fractional' );
  is( s_( _call( [], 'lastIndexOf', undef ) ), '-1', 'an empty array' );
  is( s_( _call( [ 1, '1' ], 'lastIndexOf', '1' ) ), '1', 'strict equality' );
};

subtest 'js_member_read: a plain property read and its V8 TypeError' => sub {
  # oracle: [1,2,3]|first -> 1, 'abc'|first -> a, [{'a.b': 1}, {'a.b': 2}]|join(',', 'a.b')
  # -> 1,2, undefined|first, null|last
  is( s_( $R->js_member_read( [ 1, 2, 3 ], 0 ) ), '1', 'an array index' );
  is( $R->js_member_read( 'abc', 0 ), 'a', 'a string index' );
  is( s_( $R->js_member_read( [ 1, 2, 3 ], 'length' ) ), '3', 'length' );
  is( s_( $R->js_member_read( { 'a.b' => 1, a => { b => 2 } }, 'a.b' ) ), '1', "'a.b' is one key, not a path" );
  is( _type_error( sub { $R->js_member_read( undef, 0 ) } ),
    q{TypeError: Cannot read properties of undefined (reading '0')}, 'undefined: the read throws' );
  is( _type_error( sub { $R->js_member_read( $R->None, 'length' ) } ),
    q{TypeError: Cannot read properties of null (reading 'length')}, 'null: the read throws' );

  # the key as V8 names it -- oracle: [undefined]|join(',', k) for each k
  my %reading = (
    'a string'        => [ 'x',                                  q{ (reading 'x')} ],
    'a number'        => [ 1.5,                                  q{ (reading '1.5')} ],
    'a boolean'       => [ true,                                 q{ (reading 'true')} ],
    'a plain object'  => [ { a => 1 },                           q{ (reading '#<Object>')} ],
    'a dict literal'  => [ Hash::Ordered->new( a => 1 ),         q{ (reading '#<Object>')} ],
    'keyword args'    => [ $R->make_keyword_args( { a => 1 } ),  q{ (reading '#<Object>')} ],
    'an array'        => [ [ 1, 2 ],                             '' ],
    'a SafeString'    => [ $R->SafeString->new('k'),             '' ],
    'a regex'         => [ $R->make_regex( 'a', '' ),            '' ],
    # V8 NoSideEffectsToMaybeString: an own toString, or an own constructor
    # that is no named function, leaves a plain object no form (oracle:
    # {'toString': 1}, {'constructor': 1}, toString=1, a context hash
    # {"constructor": "x"})
    'an own toString'             => [ { toString => 1 },                               '' ],
    'an own toString, ordered'    => [ Hash::Ordered->new( toString => 1 ),             '' ],
    'an own toString, kwargs'     => [ $R->make_keyword_args( { toString => 1 } ),      '' ],
    'an own constructor'          => [ { constructor => 'x' },                          '' ],
    'an own constructor, ordered' => [ Hash::Ordered->new( constructor => 1 ),          '' ],
    'an own constructor, kwargs'  => [ $R->make_keyword_args( { constructor => 1 } ),   '' ],
    'a nameless constructor'      => [ { constructor => sub { } },                      '' ],
  );
  for my $what ( sort keys %reading ) {
    my ( $key, $clause ) = @{ $reading{$what} };
    is( _type_error( sub { $R->js_member_read( undef, $key ) } ),
      'TypeError: Cannot read properties of undefined' . $clause, "key $what" );
  }

  # a function constructor shows by its name, from _js_function_name -- the
  # one place k88 fills (oracle: {'constructor': m}, a macro m -> '#<macro>')
  {
    no warnings 'redefine';
    local *Text::Nunjucks::Runtime::_js_function_name = sub { 'macro' };
    is( _type_error( sub { $R->js_member_read( undef, { constructor => sub { } } ) } ),
      q{TypeError: Cannot read properties of undefined (reading '#<macro>')}, 'key: a named function constructor' );
  }
};

subtest 'Array reduce' => sub {
  my $add = sub { $R->op_add( $_[0], $_[1] ) };
  # oracle: [1,2,3]|sum -> 6 (arr.reduce((a, b) => a + b, 0))
  is( s_( _call( [ 1, 2, 3 ], 'reduce', $add, 0 ) ), '6', 'with an initial value' );
  # oracle: macro f(a, b) -> {{ a }}+{{ b }}; [1,2,3].reduce(f) -> 1+2+3; [9].reduce(f) -> 9
  is( _call( [ 1, 2, 3 ], 'reduce', sub { "$_[0]+$_[1]" } ), '1+2+3', 'without: the first element starts' );
  is( s_( _call( [9], 'reduce', sub { 'X' } ) ), '9', 'one element, no initial value: never called' );
  # oracle: [].reduce(f, 7) -> 7, [].reduce(f) -> TypeError
  is( s_( _call( [], 'reduce', $add, 7 ) ), '7', 'an empty array returns the initial value' );
  is( _type_error( sub { _call( [], 'reduce', $add ) } ),
    'TypeError: Reduce of empty array with no initial value', 'an empty array, no initial value' );

  my $arr = [ 1, 2 ];
  my @seen;
  _call( $arr, 'reduce', sub { push @seen, [ @_[ 2, 3 ] ]; $_[1] }, 0 );
  is_deeply( [ map { $_->[0] } @seen ], [ 0, 1 ], 'the callback gets the index' );
  ok( $seen[0][1] == $arr, '... and the array' );

  # oracle: [1].reduce(x) for each x; [].reduce(5) -> number 5 (the callable check comes first)
  my @not_callable = (
    [ undef,                     'undefined' ],
    [ $R->None,                  'object null' ],
    [ true,                      'boolean true' ],
    [ 5,                         'number 5' ],
    [ 1.5,                       'number 1.5' ],
    [ 9**9**9 / 9**9**9,         'number NaN' ],
    [ 'x',                       'string "x"' ],
    [ 'y' x 100,                 'string "' . ( 'y' x 100 ) . '"' ],
    [ 'x' x 101,                 'string "' . ( 'x' x 100 ) . '<...>"' ],
    [ {},                        'object' ],
    [ [ 1, 2 ],                  'object' ],
    [ $R->SafeString->new('s'), 'object' ],
  );
  for my $case (@not_callable) {
    my ( $fn, $text ) = @$case;
    is( _type_error( sub { _call( [1], 'reduce', $fn ) } ), "TypeError: $text is not a function", $text );
  }
  # 99 units then a pair: the cut at 100 units leaves the lone high surrogate
  # (oracle: s = 'a' x 99 . '😀b')
  {
    no warnings 'surrogate';
    is( _type_error( sub { _call( [1], 'reduce', ( 'a' x 99 ) . "\x{1F600}b" ) } ),
      'TypeError: string "' . ( 'a' x 99 ) . "\x{D83D}" . '<...>" is not a function', 'cut in code units' );
  }
  is( _type_error( sub { _call( [], 'reduce', 5 ) } ), 'TypeError: number 5 is not a function', 'callable check first' );
};

subtest 'Array filter' => sub {
  # oracle: macro m(x) -> {{ x }}; [1,0,'',2].filter(m)|join(',') -> 1,0,,2 (a
  # SafeString result is an object, so truthy even when empty)
  is( s_( _call( [ 1, 0, '', 2 ], 'filter', sub { $R->mark_safe("$_[0]") } ) ), '1,0,,2', 'a SafeString result keeps every element' );
  is( s_( _call( [ 1, 0, 'a', '' ], 'filter', sub { $_[0] } ) ), '1,a', 'kept where the result is truthy (JS ToBoolean)' );
  is( s_( _call( [ '0', 0 ], 'filter', sub { $_[0] } ) ), '0', "the string '0' is truthy" );
  my $arr = [ 'a', 'b' ];
  my @seen;
  my $res = _call( $arr, 'filter', sub { push @seen, [ @_[ 1, 2 ] ]; 1 } );
  is_deeply( [ map { $_->[0] } @seen ], [ 0, 1 ], 'the callback gets the index' );
  ok( $seen[0][1] == $arr, '... and the array' );
  ok( $res != $arr, 'a new array' );
  # the length is read once; an index the callback removed is skipped
  my $shrinking = [ 1, 2, 3 ];
  my $calls     = 0;
  _call( $shrinking, 'filter', sub { $calls++; pop @$shrinking; 1 } );
  is( $calls, 2, 'a removed index is skipped' );
  my $growing = [ 1, 2 ];
  $calls = 0;
  _call( $growing, 'filter', sub { $calls++; push @$growing, 9; 1 } );
  is( $calls, 2, 'an added index is not visited' );
  # oracle: [1].filter(5) -> number 5, [1].filter() -> undefined
  is( _type_error( sub { _call( [1], 'filter', 5 ) } ), 'TypeError: number 5 is not a function', 'not callable' );
  is( _type_error( sub { _call( [1], 'filter' ) } ), 'TypeError: undefined is not a function', 'no callbackfn' );
  is( _type_error( sub { _call( [], 'filter', 5 ) } ), 'TypeError: number 5 is not a function', 'callable check first' );
};

subtest 'js_array_destructure: ([k, v]) through the iteration protocol' => sub {
  # oracle: [[1,2],"ab",[3]]|urlencode -> 1=2&a=b&3=undefined, [[1,2,3]] -> 1=2,
  # ["\u{1F600}b"] -> %F0%9F%98%80=b, [m()] with a macro m giving 'ab' -> a=b
  is_deeply( [ $R->js_array_destructure( [ 1, 2, 3 ], 2 ) ], [ 1, 2 ],     'an array: its first elements' );
  is_deeply( [ $R->js_array_destructure( [3], 2 ) ],         [ 3, undef ], '... undefined past the end' );
  is_deeply( [ $R->js_array_destructure( 'ab', 2 ) ],        [ 'a', 'b' ], 'a string: its characters' );
  is_deeply( [ $R->js_array_destructure( "\x{1F600}b", 2 ) ], [ "\x{1F600}", 'b' ], '... by code point' );
  is_deeply( [ $R->js_array_destructure( "\x{D83D}\x{DE00}b", 2 ) ], [ "\x{1F600}", 'b' ],
    '... a pair spelt as two surrogates is one code point' );
  is_deeply( [ $R->js_array_destructure( '', 2 ) ], [ undef, undef ], 'the empty string' );
  is_deeply( [ $R->js_array_destructure( $R->SafeString->new('ab'), 2 ) ], [ 'a', 'b' ], "a SafeString: its value's" );

  # oracle: [5]|urlencode, [1.5], [true], [undefined], [none], [{}], [r/x/] and a macro
  my $iter = ' is not iterable (cannot read property Symbol(Symbol.iterator))';
  my %not_iterable = (
    'a number'     => [ 5,                         'number 5' ],
    'a fraction'   => [ 1.5,                       'number 1.5' ],
    'a boolean'    => [ true,                      'boolean true' ],
    'undefined'    => [ undef,                     'undefined' ],
    'null'         => [ $R->None,                  'object null' ],
    'a plain hash' => [ { a => 1 },                'object' ],
    'a dict'       => [ Hash::Ordered->new,        'object' ],
    'a regex'      => [ $R->make_regex( 'x', '' ), 'object' ],
    'a function'   => [ sub { },                   'function' ],
  );
  for my $what ( sort keys %not_iterable ) {
    my ( $value, $text ) = @{ $not_iterable{$what} };
    is( _type_error( sub { $R->js_array_destructure( $value, 2 ) } ), 'TypeError: ' . $text . $iter, $what );
  }
};

subtest 'member_lookup: String case mapping goes through the Lib seam' => sub {
  # oracle: {{ s.toLowerCase() }}|{{ s.toUpperCase() }} with s = 'ΑΣ ß' -> ας ß|ΑΣ SS
  is( _call( "\x{391}\x{3A3} \x{DF}", 'toLowerCase' ), "\x{3B1}\x{3C2} \x{DF}", 'final sigma' );
  is( _call( "\x{391}\x{3A3} \x{DF}", 'toUpperCase' ), "\x{391}\x{3A3} SS", 'ß -> SS' );
};

subtest 'Regex symbol_replace: RegExp.prototype[Symbol.replace] (ADR 0013)' => sub {
  my $re = sub { $R->make_regex(@_) };

  # oracle: 'aaa'|replace(r/a*/g, '-') ... 'ab'|replace(r/x*|a/g, '-') -> --|-a-b-c-|-a-b-c-|-a-b-
  is( $re->( 'a*', 'g' )->symbol_replace( 'aaa', '-' ), '--', 'g: an empty match after the run' );
  is( $re->( '', 'g' )->symbol_replace( 'abc', '-' ), '-a-b-c-', 'g: every empty match' );
  is( $re->( 'x*', 'g' )->symbol_replace( 'abc', '-' ), '-a-b-c-', 'g: x* is empty everywhere' );
  is( $re->( 'x*|a', 'g' )->symbol_replace( 'ab', '-' ), '-a-b-', 'g: an empty match steps one on (not Perl s///g)' );

  # oracle: 'aab' r/a/y, r/a/gy; 'baa' r/a/gy, r/a/y -> -ab|--b|baa|baa
  is( $re->( 'a', 'y' )->symbol_replace( 'aab', '-' ), '-ab', 'y: one match at lastIndex' );
  is( $re->( 'a', 'gy' )->symbol_replace( 'aab', '-' ), '--b', 'gy: adjacent matches only' );
  is( $re->( 'a', 'gy' )->symbol_replace( 'baa', '-' ), 'baa', 'gy: no match at 0' );
  is( $re->( 'a', 'y' )->symbol_replace( 'baa', '-' ), 'baa', 'y: no match at 0' );

  # oracle: {% set re = r/a/g %}{{ re.test('xa') }}{{ re.lastIndex }}|{{ 'aXa'|replace(re, '-') }}|{{ re.lastIndex }}
  # -> true2|-X-|0
  my $g = $re->( 'a', 'g' );
  $g->test('xa');
  is( $g->symbol_replace( 'aXa', '-' ), '-X-', 'g starts at 0 whatever lastIndex was' );
  is( $g->lastIndex, 0, '... and leaves it at 0' );

  # oracle: r/a/y: test('a') -> lastIndex 1, 'aaa' -> 'a-a' lastIndex 2, 'aaa' -> 'aa-' lastIndex 3
  my $y = $re->( 'a', 'y' );
  $y->test('a');
  is( $y->symbol_replace( 'aaa', '-' ), 'a-a', 'y starts at lastIndex' );
  is( $y->lastIndex, 2, '... and moves it past the match' );
  is( $y->symbol_replace( 'aaa', '-' ), 'aa-', 'again from there' );
  is( $y->lastIndex, 3, '... lastIndex 3' );

  # oracle: 'abc'|replace(r/b/) / (r/b/, null) / (r/b/, 5) / (r/b/, [1,'$&']) -> aundefinedc|anullc|a5c|a1,bc
  is( $re->( 'b', '' )->symbol_replace( 'abc', undef ),       'aundefinedc', 'undefined replaceValue' );
  is( $re->( 'b', '' )->symbol_replace( 'abc', $R->None ),    'anullc',      'null replaceValue' );
  is( $re->( 'b', '' )->symbol_replace( 'abc', 5 ),           'a5c',         'a number' );
  is( $re->( 'b', '' )->symbol_replace( 'abc', [ 1, '$&' ] ), 'a1,bc',       'an array: ToString, then the pattern' );

  # oracle: macro replacers -- 'abcb' r/b/g -> a[b@1/abcb]c[b@3/abcb];
  # 'xaby' r/(a)(z)?b/ -> x[ab|a|true|1]y; 'xab' r/(?<n>a)b/ -> groups.n a at 1
  my @calls;
  is( $re->( 'b', 'g' )->symbol_replace( 'abcb', sub { push @calls, [@_]; '[' . $_[0] . ']' } ), 'a[b]c[b]',
    'a coderef replaces each match' );
  is_deeply( \@calls, [ [ 'b', 1, 'abcb' ], [ 'b', 3, 'abcb' ] ], '... called with (matched, position, string)' );
  @calls = ();
  $re->( '(a)(z)?b', '' )->symbol_replace( 'xaby', sub { push @calls, [@_]; '' } );
  is_deeply( \@calls, [ [ 'ab', 'a', undef, 1, 'xaby' ] ], 'captures, undefined for one that did not take part' );
  @calls = ();
  $re->( '(?<n>a)b', '' )->symbol_replace( 'xab', sub { push @calls, [@_]; '' } );
  is_deeply( [ @{ $calls[0] }[ 0 .. 3 ] ], [ 'ab', 'a', 1, 'xab' ], 'named groups: matched, captures, position, string' );
  isa_ok( $calls[0][4], 'Hash::Ordered', '... then the groups object, an engine-built ordered dict' );
  is_deeply( [ $calls[0][4]->as_list ], [ n => 'a' ], '... holding the group' );

  # oracle: macro f(m,a,b,p,s,g) iterating g: 'ab' r/(?<z>a)(?<b>b)/ -> z=a;b=b;
  # 'a' r/(?<y>x)?(?<c>a)/ -> y=;c=a; 'b' r/(?<n>a)|(?<m>c)|(?<n>b)/ -> n=b;m=;
  my $groups = sub {
    my ( $source, $string ) = @_;
    my $g;
    $re->( $source, '' )->symbol_replace( $string, sub { $g = $_[-1]; '' } );
    return [ $g->as_list ];
  };
  is_deeply( $groups->( '(?<z>a)(?<b>b)', 'ab' ), [ z => 'a', b => 'b' ], 'groups iterate in group order, not sorted' );
  is_deeply( $groups->( '(?<y>x)?(?<c>a)', 'a' ), [ y => undef, c => 'a' ], 'a group that did not take part is undefined' );
  is_deeply( $groups->( '(?<n>a)|(?<m>c)|(?<n>b)', 'b' ), [ n => 'b', m => undef ],
    'a duplicate name keeps its first place and the value of the group that took part' );
  is_deeply( $groups->( '(?<z>a)[(?<q>](?<b>b)', 'a(b' ), [ z => 'a', b => 'b' ], 'no group inside a class' );

  # oracle: '😀ab😀b'|replace(r/b/g, '[$`]') -> 😀a[😀a]😀[😀ab😀]
  @calls = ();
  is( $re->( 'b', 'g' )->symbol_replace( "\x{1F600}ab\x{1F600}b", '[$`]' ),
    "\x{1F600}a[\x{1F600}a]\x{1F600}[\x{1F600}ab\x{1F600}]", '$` cuts at the match' );
  $re->( 'b', 'g' )->symbol_replace( "\x{1F600}ab\x{1F600}b", sub { push @calls, $_[1]; '' } );
  is_deeply( \@calls, [ 3, 6 ], 'positions count code units (ADR 0012)' );
};

done_testing;

# helper: look a member up and call it via call_wrap (the compiler's path)
sub _call {
  my ( $obj, $name, @args ) = @_;
  my $fn = $R->member_lookup( $obj, $name );
  return $R->call_wrap( $fn, $name, undef, \@args );
}

BEGIN {
  package TN_Test_Obj;
  sub new { my ( $c, $name ) = @_; bless { name => $name }, $c }
  sub greet { my ($self) = @_; 'hi ' . $self->{name} }
  sub name  { $_[0]->{name} }

  package TN_Test_Ctx;
  sub new { my ( $c, $h ) = @_; bless { h => $h }, $c }
  sub lookup { my ( $self, $name ) = @_; $self->{h}{$name} }
}
