#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use builtin qw( true false is_bool );
use Cwd ();
use Fcntl ();
use JSON::MaybeXS ();
use Path::Tiny ();
use POSIX ();

no warnings 'experimental::builtin';

# Perl-side unit tests for Text::Nunjucks::Lib (port of src/lib.js). lib.js is
# foundation utility code exercised end-to-end only through filters/runtime/
# render (not yet ported), so it has no direct upstream .t counterpart and is
# not replayed by the corpus harness. Values that depend on JS semantics
# (escape output, prettified error messages) were confirmed with maint/oracle.js
# and are pinned here; the rest are structural Perl-API assertions.

use_ok('Text::Nunjucks::Lib');
use_ok('Text::Nunjucks::Lib::TemplateError');
use_ok('Text::Nunjucks::Lib::Error');

use_ok('Hash::Ordered');

my $L = 'Text::Nunjucks::Lib';

#### escape / lookupEscape  (oracle-confirmed: & " ' < > and backslash; backtick NOT escaped)

subtest 'escape' => sub {
  # input:  a&b"c'd<e>f\g`h   (context s in maint/oracle.js probe)
  my $in  = q{a&b"c'd<e>f\g`h};
  my $exp = q{a&amp;b&quot;c&#39;d&lt;e&gt;f&#92;g`h};
  is( $L->escape($in), $exp, 'all five entities plus backslash, backtick left alone' );
  is( $L->escape(q{&<>'"}), q{&amp;&lt;&gt;&#39;&quot;}, 'literal escape order' );
  is( $L->escape('plain text'), 'plain text', 'no-op on plain text' );

  is( $L->lookup_escape('&'),  '&amp;',  'lookup &' );
  is( $L->lookup_escape('\\'), '&#92;',  'lookup backslash' );
  is( $L->lookup_escape('`'),  undef,    'backtick not in map' );
};

#### kind checks (ADR 0001)

subtest 'is_function / is_array / is_object' => sub {
  ok( $L->is_function( sub { } ), 'coderef is a function' );
  ok( !$L->is_function(5),        'number is not a function' );

  ok( $L->is_array( [ 1, 2 ] ), 'arrayref is an array' );
  ok( !$L->is_array( {} ),      'hashref is not an array' );
  ok( !$L->is_array(5),         'number is not an array' );

  ok( $L->is_object( {} ),        'hashref is an object' );
  ok( !$L->is_object( [] ),       'arrayref is not an object' );
  ok( !$L->is_object('x'),        'string is not an object' );
  # oracle: {{ {b: 1, a: 2}|list }} iterates b, a -- a dict literal is a plain object
  ok( $L->is_object( Hash::Ordered->new( a => 1 ) ), 'an ordered dict (ADR 0011) is an object' );
  ok( !$L->is_object( bless {}, 'TN_Lib_Other' ),   'another blessed object is not' );
};

subtest 'is_string (ADR 0001 kinds)' => sub {
  ok( $L->is_string('5'),  'numeric string is a string' );
  ok( $L->is_string(''),   'empty string is a string' );
  ok( !$L->is_string(5),   'number is not a string' );
  ok( !$L->is_string(true), 'boolean is not a string' );
  ok( !$L->is_string(undef), 'undef is not a string' );
  ok( !$L->is_string( [] ),  'arrayref is not a string' );
};

#### hasOwnProp

# 'Name: message' of what $code throws, or 'no error'.
sub thrown {
  my ($code) = @_;
  my $err = do { local $@; eval { $code->(); 1 } ? undef : $@ };
  return 'no error' unless defined $err;
  return ref($err) ? $err->name . ': ' . $err->message : "died: $err";
}

subtest 'has_own_prop' => sub {
  ok( $L->has_own_prop( { a => 1 }, 'a' ), 'hash: present key' );
  ok( !$L->has_own_prop( { a => 1 }, 'b' ), 'hash: absent key' );
  ok( $L->has_own_prop( [ 10, 20 ], '0' ), 'array: index 0' );
  ok( $L->has_own_prop( [ 10, 20 ], 1 ),   'array: index 1' );
  ok( !$L->has_own_prop( [ 10, 20 ], 2 ),  'array: out-of-range index' );
  ok( !$L->has_own_prop( 'scalar', 'x' ),  'non-container: false' );

  # ObjProto.hasOwnProperty.call(obj, k), oracle-measured through groupby(attr)
  my $R = 'Text::Nunjucks::Runtime';
  ok( $L->has_own_prop( Hash::Ordered->new( a => undef ), 'a' ), 'ordered dict: present key, undefined value' );
  ok( !$L->has_own_prop( Hash::Ordered->new( a => 1 ), 'b' ),    'ordered dict: absent key' );
  ok( $L->has_own_prop( [ 10, 20 ], 'length' ), 'array: length is own' );
  ok( !$L->has_own_prop( [ 10, 20 ], '01' ),    "array: '01' is no index" );
  ok( !$L->has_own_prop( [ 10, 20 ], 'push' ),  'array: a method is inherited' );
  ok( $L->has_own_prop( 'ab', 1 ),              'string: a code-unit index' );
  ok( $L->has_own_prop( "\x{1F600}", 1 ),       'string: indices count code units (ADR 0012)' );
  ok( !$L->has_own_prop( 'ab', 2 ),             'string: past the end' );
  ok( !$L->has_own_prop( 'ab', '01' ),          "string: '01' is no index" );
  ok( $L->has_own_prop( 'ab', 'length' ),       'string: length is own' );
  my $safe = $R->SafeString->new('ab');
  ok( $L->has_own_prop( $safe, 'val' ),    'SafeString: this.val' );
  ok( $L->has_own_prop( $safe, 'length' ), 'SafeString: this.length' );
  ok( !$L->has_own_prop( $safe, '0' ),     'SafeString: no index (a String object, not a string)' );
  my $re = $R->make_regex( 'a', 'g' );
  ok( $L->has_own_prop( $re, 'lastIndex' ), 'regex: lastIndex is own' );
  ok( !$L->has_own_prop( $re, 'source' ),   'regex: source is an inherited accessor' );
  ok( !$L->has_own_prop( 5, 'x' ),          'number: nothing' );
  ok( !$L->has_own_prop( true, 't' ),       'boolean: nothing' );

  # ToPropertyKey of k (oracle: groupby(1), groupby(true), groupby(['a']))
  ok( $L->has_own_prop( { 1 => 'x' }, 1 ),           'a number key is its ToString' );
  ok( $L->has_own_prop( { '1.5' => 'x' }, 1.5 ),     '... 1.5' );
  ok( $L->has_own_prop( { true => 'x' }, true ),     "true is 'true'" );
  ok( !$L->has_own_prop( { 1 => 'x' }, true ),       '... not 1' );
  ok( $L->has_own_prop( { a => 1 }, ['a'] ),         "['a'] is 'a'" );
  # null and undefined keys never come from a template: upstream lib.hasOwnProp in node
  ok( $L->has_own_prop( { null => 1 }, $R->None ),   "null is 'null'" );
  ok( $L->has_own_prop( { undefined => 1 }, undef ), "undefined is 'undefined'" );
  ok( $L->has_own_prop( { a => 1 }, $R->SafeString->new('a') ), 'a SafeString is its value' );

  # ToObject(obj) throws on undefined and null (oracle: [u]|groupby('a'))
  is( thrown( sub { $L->has_own_prop( undef, 'a' ) } ),
    'TypeError: Cannot convert undefined or null to object', 'undefined' );
  is( thrown( sub { $L->has_own_prop( $R->None, 'a' ) } ),
    'TypeError: Cannot convert undefined or null to object', 'null' );
};

#### _prepareAttributeParts -- exercises the JS "'0' is truthy" trap

subtest '_prepare_attribute_parts' => sub {
  is_deeply( $L->_prepare_attribute_parts('a.b.c'), [qw( a b c )], 'dotted path' );
  is_deeply( $L->_prepare_attribute_parts('x'),     ['x'],         'single part' );
  is_deeply( $L->_prepare_attribute_parts(undef),   [],            'undef -> empty' );
  is_deeply( $L->_prepare_attribute_parts(''),      [],            'empty string -> empty' );
  is_deeply( $L->_prepare_attribute_parts(0),       [],            'number 0 is falsy in JS -> empty' );
  is_deeply( $L->_prepare_attribute_parts('0'),     ['0'],         "string '0' is TRUTHY in JS -> ['0']" );
};

#### _falsy -- the isolated JS !x seam (F4), keyed to ADR 0001 kinds

subtest '_falsy (JS !x)' => sub {
  ok( $L->_falsy(undef),  'undef is falsy' );
  ok( $L->_falsy(0),      'number 0 is falsy' );
  ok( $L->_falsy(''),     'empty string is falsy' );
  ok( $L->_falsy(false),  'boolean false is falsy' );
  ok( !$L->_falsy('0'),   "string '0' is TRUTHY in JS (Perl disagrees)" );
  ok( !$L->_falsy(1),     'number 1 is truthy' );
  ok( !$L->_falsy('x'),   'non-empty string is truthy' );
  ok( !$L->_falsy(true),  'boolean true is truthy' );
  ok( !$L->_falsy( [] ),  'arrayref is truthy' );
  ok( !$L->_falsy( {} ),  'hashref is truthy' );
};

#### getAttrGetter

subtest 'get_attr_getter' => sub {
  my $g = $L->get_attr_getter('a.b');
  is( $g->( { a => { b => 42 } } ), 42, 'nested lookup' );
  is( $g->( { a => {} } ), undef, 'missing leaf -> undef' );
  is( $g->( { x => 1 } ),  undef, 'missing branch -> undef' );

  my $id = $L->get_attr_getter(undef);
  is_deeply( $id->( { a => 1 } ), { a => 1 }, 'empty parts -> identity' );

  # oracle, through groupby(attr)
  my $R = 'Text::Nunjucks::Runtime';
  is_deeply( $L->get_attr_getter( $R->None )->( { a => 1 } ), { a => 1 }, 'null is falsy too: identity' );
  is( $L->get_attr_getter('a.b')->( Hash::Ordered->new( a => Hash::Ordered->new( b => 7 ) ) ), 7,
    'ordered dicts (template literals) are read' );
  is( $L->get_attr_getter('length')->( [ 1, 2 ] ), 2,   "an array's length" );
  is( $L->get_attr_getter('1')->('ab'),            'b', "a string's code unit" );
  is( $L->get_attr_getter('length')->( $R->SafeString->new('abc') ), 3, "a SafeString's length" );
  is( $L->get_attr_getter('lastIndex')->( $R->make_regex( 'a', 'g' ) ), 0, "a regex's lastIndex" );
  is( $L->get_attr_getter(1)->( [ 'x', 'y' ] ), 'y', 'a number attribute is one part' );
  is( $L->get_attr_getter( $R->SafeString->new('a') )->( { a => 5 } ), 5, 'a SafeString attribute is one part' );
  is( $L->get_attr_getter('length.x')->('ab'), undef, 'a number owns nothing' );
  is( thrown( sub { $L->get_attr_getter('a.b')->( { a => $R->None } ) } ),
    'TypeError: Cannot convert undefined or null to object', 'a null on the way throws' );
  is( thrown( sub { $L->get_attr_getter('a')->(undef) } ),
    'TypeError: Cannot convert undefined or null to object', 'an undefined item throws' );
};

#### groupBy

subtest 'group_by' => sub {
  my $items = [ { k => 'x', n => 1 }, { k => 'y', n => 2 }, { k => 'x', n => 3 } ];
  my $grouped = $L->group_by( $items, 'k' );
  is( scalar( @{ $grouped->get('x') } ), 2, 'two items under x' );
  is( scalar( @{ $grouped->get('y') } ), 1, 'one item under y' );
  is( $grouped->get('x')->[1]{n}, 3, 'preserves item order within a group' );

  my $with_undef = $L->group_by( [ { k => 'a' }, {} ], 'k' );
  ok( $with_undef->exists('undefined'), 'undefined key coerces to "undefined"' );

  my $by_fn = $L->group_by( [ 1, 2, 3, 4 ], sub { $_[0] % 2 } );
  is_deeply( $L->keys($by_fn), [ 0, 1 ], 'function iterator groups by return value' );

  # The result is an engine-built object (ADR 0011, k51): groups in first-seen
  # order, array-index keys first. oracle, groupby('t') over t = b, 2019, a,
  # 10, 2018, 9 -> 9|10|2018|2019|b|a|; over green, blue, (none), green ->
  # green|blue|undefined|
  my $years = $L->group_by( [ map { { t => $_ } } qw( b 2019 a 10 2018 9 ) ], 't' );
  is_deeply( $L->keys($years), [qw( 9 10 2018 2019 b a )], 'ordered dict, JS key order' );
  my $colours = $L->group_by( [ { t => 'green' }, { t => 'blue' }, { x => 1 }, { t => 'green' } ], 't' );
  is_deeply( $L->keys($colours), [qw( green blue undefined )], 'groups in first-seen order, not sorted' );

  my $err;
  eval { $L->group_by( [ {} ], 'k', true ); 1 } or $err = $@;
  ok( ref($err) && $err->isa('Text::Nunjucks::Lib::Error'), 'throwOnUndefined dies with an Error object' );
  is( $err->name, 'TypeError', 'error name is TypeError' );
  is( $err->message, 'groupby: attribute "k" resolved to undefined', 'error message text' );

  # result[key] is the key's ToPropertyKey (oracle, groupby by a macro or an
  # attribute giving these keys)
  my $R    = 'Text::Nunjucks::Runtime';
  my @keys = ( true, $R->None, 0.3, 0.30000000000000004, -0.0, 0, 1e21, '1e+21', [ 1, [ 2, $R->None ] ],
    $R->SafeString->new('s'), $R->make_regex( 'a', 'g' ), Hash::Ordered->new );
  my $by_key = $L->group_by( [ 0 .. $#keys ], sub { $keys[ $_[0] ] } );
  is_deeply( $L->keys($by_key),
    [ '0', 'true', 'null', '0.3', '0.30000000000000004', '1e+21', '1,2,', 's', '/a/g', '[object Object]' ],
    'keys through JS ToString: -0 and 0 meet, 1e21 and "1e+21" meet' );
  is( scalar @{ $by_key->get('0') },     2, '-0 and 0 are one group' );
  is( scalar @{ $by_key->get('1e+21') }, 2, '1e21 and "1e+21" are one group' );
  my $true_one = $L->group_by( [ { t => true }, { t => 'true' } ], 't' );
  is( scalar @{ $true_one->get('true') }, 2, "true groups with 'true'" );

  # i < obj.length and obj[i] are JS reads (oracle)
  is_deeply( $L->keys( $L->group_by( 'aba', sub { $_[0] } ) ), [ 'a', 'b' ], 'a string groups its code units' );
  is_deeply( $L->keys( $L->group_by( 5, 't' ) ), [], 'a number has no length' );
  is_deeply( $L->keys( $L->group_by( Hash::Ordered->new( length => 1, 0 => { t => 'x' } ), 't' ) ), ['x'],
    'an array-like object' );
  is( thrown( sub { $L->group_by( undef, 't' ) } ),
    "TypeError: Cannot read properties of undefined (reading 'length')", 'undefined input' );
  is( thrown( sub { $L->group_by( $R->None, 't' ) } ),
    "TypeError: Cannot read properties of null (reading 'length')", 'null input' );
  is( thrown( sub { $L->group_by( $R->SafeString->new('ab'), 't' ) } ),
    'TypeError: Cannot convert undefined or null to object', "a SafeString's obj[i] is undefined" );

  # `${val}` in the throwOnUndefined message is val's ToString (oracle)
  for my $c ( [ 5, '5' ], [ [ 'a', 'b' ], 'a,b' ], [ { a => 1 }, '[object Object]' ], [ true, 'true' ],
    [ 0.30000000000000004, '0.30000000000000004' ], [ $R->SafeString->new('a'), 'a' ] )
  {
    is( thrown( sub { $L->group_by( [ {} ], $c->[0], true ) } ),
      'TypeError: groupby: attribute "' . $c->[1] . '" resolved to undefined', "message names $c->[1]" );
  }
  # upstream lib.groupBy in node; Environment's !!opts.throwOnUndefined makes a
  # template's 1 a true before it gets here
  is( thrown( sub { $L->group_by( [ {} ], 'k', 1 ) } ), 'no error', 'throwOnUndefined must be === true' );
};

#### toArray

subtest 'to_array' => sub {
  my $src = [ 1, 2, 3 ];
  my $cp  = $L->to_array($src);
  is_deeply( $cp, [ 1, 2, 3 ], 'copies contents' );
  isnt( $cp, $src, 'returns a new arrayref' );
  is_deeply( $L->to_array('ab'), [qw( a b )], 'string -> chars' );
  # node: Array.prototype.slice.call('a😀') -> ['a', '\ud83d', '\ude00']
  is_deeply( $L->to_array("a\x{1F600}"), [ 'a', "\x{D83D}", "\x{DE00}" ],
    'string -> UTF-16 code units, an astral char as two lone surrogates (ADR 0012)' );

  # Array.prototype.slice.call(obj), oracle-measured through select
  my $R = 'Text::Nunjucks::Runtime';
  is( thrown( sub { $L->to_array(undef) } ),     'TypeError: Cannot convert undefined or null to object', 'undefined' );
  is( thrown( sub { $L->to_array( $R->None ) } ), 'TypeError: Cannot convert undefined or null to object', 'null' );
  is_deeply( $L->to_array( Hash::Ordered->new( length => 2, 0 => 1, 1 => 0 ) ), [ 1, 0 ], 'an array-like object' );
  is_deeply( $L->to_array( { length => '2', 0 => 'x', 1 => 'y' } ), [ 'x', 'y' ], 'ToLength of a string length' );
  is_deeply( $L->to_array( { length => 1.7, 0 => 'x', 1 => 'y' } ), ['x'], '... truncated' );
  is_deeply( $L->to_array( { length => -1, 0 => 'x' } ), [], '... negative is 0' );
  is_deeply( $L->to_array( Hash::Ordered->new( length => 3, 1 => undef ) ), [undef],
    'a missing index (a hole in JS) is left out, a present undefined kept' );
  is_deeply( $L->to_array( $R->SafeString->new('ab') ), [], 'a SafeString has a length but no indices' );
  is_deeply( $L->to_array($_), [], 'no length: ' . ( ref($_) || $_ ) )
    for 5, true, sub { }, $R->make_regex( 'a', '' ), { a => 1 };
  is( thrown( sub { $L->to_array( { length => 9**9**9 } ) } ),   'RangeError: Invalid array length', 'Infinity' );
  is( thrown( sub { $L->to_array( { length => 4294967296 } ) } ), 'RangeError: Invalid array length', '2^32' );
};

#### without

subtest 'without' => sub {
  is_deeply( $L->without( [ 1, 2, 3, 2, 1 ], 2 ), [ 1, 3, 1 ], 'removes one value' );
  is_deeply( $L->without( [ 1, 2, 3 ], 2, 3 ), [1], 'removes several values' );
  is_deeply( $L->without( undef ), [], 'undef array -> empty' );
  is_deeply( $L->without( [qw( a b c )], 'b' ), [qw( a c )], 'strings' );
};

#### repeat

subtest 'repeat' => sub {
  is( $L->repeat( 'ab', 3 ), 'ababab', 'three times' );
  is( $L->repeat( 'x', 0 ),  '',       'zero times -> empty' );
  is( $L->repeat( 'x', -1 ), '',       'negative -> empty' );
  # F1 regression: JS `for (i=0; i<n; i++)` runs 3x for n=2.5, not Perl 1..$n's 2x.
  # Reached via center(): "test"|center(9) -> "  test   " uses repeat(' ', 2.5).
  is( $L->repeat( 'x',  2.5 ), 'xxx',  'fractional n runs the loop ceil times (F1)' );
  is( $L->repeat( 'ab', 1.5 ), 'abab', 'fractional n, multi-char' );
};

#### each

subtest 'each' => sub {
  my @seen;
  $L->each( [ 10, 20, 30 ], sub { my ( $v, $i ) = @_; push @seen, "$i:$v" } );
  is_deeply( \@seen, [ '0:10', '1:20', '2:30' ], 'callback gets value and index' );

  my @none;
  $L->each( undef, sub { push @none, 1 } );
  is_deeply( \@none, [], 'undef obj is a no-op' );
};

#### map

subtest 'map' => sub {
  is_deeply( $L->map( [ 1, 2, 3 ], sub { $_[0] * 2 } ), [ 2, 4, 6 ], 'maps values' );
  is_deeply(
    $L->map( [ 10, 20 ], sub { my ( $v, $i ) = @_; "$i:$v" } ),
    [ '0:10', '1:20' ],
    'callback gets index'
  );
  is_deeply( $L->map(undef, sub { }), [], 'undef obj -> empty' );
  my $arr = [ 1, 2 ];
  my @args;
  $L->map( $arr, sub { push @args, [@_] } );
  ok( $args[1][2] == $arr, 'native Array.map: the callback also gets the array' );
};

# The array-like branch reads obj.length / obj[i] and compares with JS < --
# Runtime's member_lookup and op_lt. Lib loads Runtime itself: this file loads
# only Lib, so no require here -- the subtest also pins that loading Lib alone
# suffices. Every value is oracle-grounded through upstream's
# lib.map(val, v => v), the reverse filter.
subtest 'map: array-likes, read through Runtime' => sub {
  my $R  = 'Text::Nunjucks::Runtime';
  my $id = sub { $_[0] };

  # oracle: {{ o|reverse|join(',') }} with o = {length: 2, 0: 'x', 1: 'y'} -> y,x;
  # with length '2' -> y,x; length '1.5' and [2] -> b,a; length true -> a
  is_deeply( $L->map( Hash::Ordered->new( length => 2, 0 => 'x', 1 => 'y' ), $id ), [qw( x y )], 'length and indices' );
  is_deeply( $L->map( { length => '2', 0 => 'x', 1 => 'y' }, $id ), [qw( x y )], 'a string length compares as a number' );
  is_deeply( $L->map( { length => '1.5', 0 => 'a', 1 => 'b' }, $id ), [qw( a b )], "'1.5': i < length twice, no length set" );
  is_deeply( $L->map( { length => [2], 0 => 'a', 1 => 'b' }, $id ), [qw( a b )], '[2] as length' );
  is_deeply( $L->map( { length => true, 0 => 'a' }, $id ), ['a'], 'true as length' );
  # oracle: {{ o|reverse|length }} with o = {key: 1, length: 5} -> 5 (all undefined)
  is_deeply( $L->map( { key => 1, length => 5 }, $id ), [ (undef) x 5 ], 'missing indices are undefined' );
  # oracle: '{% macro m() %}abc{% endmacro %}{{ m()|reverse }}' -> ,, -- a SafeString
  # has a length and no index access
  is_deeply( $L->map( $R->SafeString->new('abc'), $id ), [ (undef) x 3 ], 'a SafeString' );
  # oracle: {{ ('a😀b'|reverse).length }} -> 4 -- a string's code units
  {
    no warnings 'surrogate';
    is_deeply( $L->map( "a\x{1F600}b", $id ), [ 'a', "\x{D83D}", "\x{DE00}", 'b' ], 'a string maps its code units' );
  }
  # oracle: 5|reverse, {a: 1}|reverse, null|reverse -> nothing
  is_deeply( $L->map( 5, $id ),          [], 'a number has no length' );
  is_deeply( $L->map( { a => 1 }, $id ), [], 'an object without length' );
  is_deeply( $L->map( $R->None, $id ),   [], 'null (obj == null)' );

  my @args;
  $L->map( { length => 1, 0 => 'v' }, sub { push @args, [@_] } );
  is_deeply( \@args, [ [ 'v', 0 ] ], 'the callback gets (value, index)' );

  # oracle: {length: 2.5}|reverse and {length: -1}|reverse -> RangeError; {length: -0} -> nothing
  for my $length ( 2.5, -1 ) {
    my $err = eval { $L->map( { length => $length }, $id ); 1 } ? undef : $@;
    is( ref($err) ? $err->name . ': ' . $err->message : 'no error', 'RangeError: Invalid array length',
      "length $length: results.length = obj.length throws" );
  }
  is_deeply( $L->map( { length => -0.0 }, $id ), [], 'length -0' );
};

#### asyncIter / asyncFor  (CPS, ADR 0003 -- run synchronously here)

subtest 'async_iter' => sub {
  my @got;
  $L->async_iter(
    [ 1, 2, 3 ],
    sub { my ( $item, $i, $next, $cb ) = @_; push @got, $item; $next->(); },
    sub { push @got, 'done'; },
  );
  is_deeply( \@got, [ 1, 2, 3, 'done' ], 'iterates then calls cb' );
};

subtest 'async_for' => sub {
  my @got;
  $L->async_for(
    { a => 1 },
    sub { my ( $k, $v, $i, $len, $next ) = @_; push @got, "$k=$v", "len=$len"; $next->(); },
    sub { push @got, 'done'; },
  );
  is_deeply( \@got, [ 'a=1', 'len=1', 'done' ], 'iterates key/value then calls cb' );

  # JS `keys(arr || {})` -- a JS-falsy iterable (0, '', false, undef) must be an
  # empty loop, not a crash on deref. (F2; None is guarded upstream in Runtime.)
  for my $falsy ( 0, '', undef, false ) {
    my @none;
    my $ok = eval {
      $L->async_for( $falsy, sub { push @none, 1 }, sub { push @none, 'done' } );
      1;
    };
    ok( $ok, 'async_for on a falsy iterable does not crash' );
    is_deeply( \@none, ['done'], 'falsy iterable -> empty loop, cb still fires' );
  }
};

#### indexOf -- strict equality (===)

subtest 'index_of (strict ===)' => sub {
  is( $L->index_of( [ 1, 2, 3 ], 2 ), 1, 'finds a number' );
  is( $L->index_of( [ 1, 2, 3 ], 9 ), -1, 'absent -> -1' );
  is( $L->index_of( [ 'a', 'b' ], 'b' ), 1, 'finds a string' );
  is( $L->index_of( [ 1, 2, 3 ], '3' ), -1, "number 3 !== string '3'" );
  is( $L->index_of( [ '1', '2', '3' ], '3' ), 2, 'string matches string' );
  is( $L->index_of( [ 1, 2, 3, 2 ], 2, 2 ), 3, 'fromIndex skips earlier match' );
};

#### keys / _entries / _values  (order is the open k3 decision -> compare as sets)

subtest 'keys / _entries / _values' => sub {
  my $obj = { a => 1, b => 2 };
  is_deeply( [ sort @{ $L->keys($obj) } ], [qw( a b )], 'keys (as set)' );
  is_deeply(
    [ sort { $a->[0] cmp $b->[0] } @{ $L->_entries($obj) } ],
    [ [ 'a', 1 ], [ 'b', 2 ] ],
    '_entries (as set)'
  );
  is_deeply( [ sort @{ $L->_values($obj) } ], [ 1, 2 ], '_values (as set)' );

  my $ordered = Hash::Ordered->new( b => 1, a => 2 );
  is_deeply( $L->_entries($ordered), [ [ 'b', 1 ], [ 'a', 2 ] ], '_entries of an ordered dict reads its values' );
  is_deeply( $L->_values($ordered), [ 1, 2 ], '_values of an ordered dict' );
};

# oracle: '{% macro m() %}ab{% endmacro %}{% for p in m()|list %}{{ p.key }}={{ p.value }};{% endfor %}'
# -> val=ab;length=2; -- a SafeString's own properties in constructor order
subtest 'is_object / keys / _entries: a SafeString is an ordinary object' => sub {
  my $safe = Text::Nunjucks::Runtime->SafeString->new('ab');
  ok( $L->is_object($safe), 'is_object' );
  is_deeply( $L->keys($safe),     [qw( val length )], 'keys: this.val, then this.length' );
  is_deeply( $L->_entries($safe), [ [ 'val', 'ab' ], [ 'length', 2 ] ], '_entries' );
};

subtest 'keys over a primitive or a function enumerates nothing' => sub {
  # oracle: 5|urlencode, true|urlencode, none|urlencode, undefined|urlencode and
  # a macro|urlencode all render '' -- for-in over them yields no key
  is_deeply( $L->keys(undef),                           [], 'undefined' );
  is_deeply( $L->keys( Text::Nunjucks::Runtime->None ), [], 'null' );
  is_deeply( $L->keys(5),                               [], 'a number' );
  is_deeply( $L->keys(true),                            [], 'a boolean' );
  is_deeply( $L->keys( sub { } ),                       [], 'a function' );
};

# ADR 0011 -- ordering policy at the keys() seam. The "as set" assertions above
# cannot fail when the policy regresses, so pin the actual order here. Plain
# caller hashes are key-sorted (the documented divergence from JS insertion
# order); Hash::Ordered is honoured in its own order (template literals,
# engine-built objects). Keys here are never array indices; those come first
# in both, see the k51 subtests below.
subtest 'keys orders plain hashes key-sorted; Hash::Ordered in own order (ADR 0011)' => sub {
  # Insertion order on the Perl side is { b, a, c } -- with PERL_HASH_SEED off,
  # Perl's hash order is deterministic, but the canonical seed is on and the
  # sort here is what every consumer of Lib::keys depends on.
  my $plain = { b => 1, a => 2, c => 3 };
  is_deeply( $L->keys($plain), [qw( a b c )], 'plain hashref -> key-sorted' );

  # Reverse the insertion order to make sure it really is the keys' alphabetical
  # order, not Perl's hash-iteration accident.
  my $reversed = { z => 1, y => 2, m => 3 };
  is_deeply( $L->keys($reversed), [qw( m y z )], 'plain hashref -> key-sorted, second sample' );

  # Hash::Ordered is honoured in its own order.
  my $ordered = Hash::Ordered->new( b => 1, a => 2 );
  is_deeply( $L->keys($ordered), [qw( b a )], 'Hash::Ordered -> its own order' );

  # The seam's callers inherit the policy. async_for / _entries / _values /
  # extend / member_lookup all go through keys(); cover the first two directly.
  # async_for's iter callback is (k, val, i, len, next) -- 5 args; a shorter
  # destructure would bind $next to $len and crash on the first recursion.
  my @seen;
  $L->async_for(
    $plain,
    sub { my ( $k, $v, $i, $len, $next ) = @_; push @seen, "$k=$v"; $next->(); },
    sub { },
  );
  is_deeply( \@seen, [ 'a=2', 'b=1', 'c=3' ], 'async_for iterates plain hashref key-sorted' );

  is_deeply(
    $L->_entries($plain),
    [ [ 'a', 2 ], [ 'b', 1 ], [ 'c', 3 ] ],
    '_entries follows keys() -> key-sorted'
  );
  is_deeply( $L->_values($plain), [ 2, 1, 3 ], '_values follows keys() -> key-sorted' );
};

# ADR 0011 amendment (k51): JS enumerates own keys in OrdinaryOwnPropertyKeys
# order -- array indices (canonical integers 0 .. 2^32 - 2) first, ascending,
# then the other keys in insertion order. Every expected order below is the
# oracle's, for a dict literal with the same keys in the same insertion order:
#   {% for k, v in {...} %}{{ k }};{% endfor %}
subtest 'keys: array-index keys first, ascending, on an ordered dict (ADR 0011, k51)' => sub {
  my @order = ( map { ( $_ => 1 ) } qw( b 2 1 ) );
  is_deeply( $L->keys( Hash::Ordered->new(@order) ), [qw( 1 2 b )], '{b, 2, 1} -> 1;2;b;' );

  # oracle: 9;10;4294967294;a;01;-1;4294967295;1.5;
  my $boundary = Hash::Ordered->new( map { ( $_ => 1 ) } qw( a 10 9 01 -1 4294967295 4294967294 1.5 ) );
  is_deeply(
    $L->keys($boundary),
    [qw( 9 10 4294967294 a 01 -1 4294967295 1.5 )],
    '2^32 - 2 is the last index; 2^32 - 1, 01, -1, 1.5 keep insertion order',
  );

  # oracle: 0;x;00;-0;+1; 1;1 ;1e3;0x1;;٣;１;
  my @zero = ( 'x', '0', '00', '-0', '+1', ' 1', '1 ', '1e3', '0x1', '', "\x{663}", "\x{FF11}" );
  is_deeply(
    $L->keys( Hash::Ordered->new( map { ( $_ => 1 ) } @zero ) ),
    [ '0', 'x', '00', '-0', '+1', ' 1', '1 ', '1e3', '0x1', '', "\x{663}", "\x{FF11}" ],
    'only canonical ASCII decimal strings are indices: 0 is, 00 -0 +1 1e3 0x1 and non-ASCII digits are not',
  );
  # oracle: {"x":1,"1٣":2,"2":3,"1１":4} iterates [2][x][1٣][1１]
  is_deeply(
    $L->keys( Hash::Ordered->new( x => 1, "1\x{663}" => 2, 2 => 3, "1\x{FF11}" => 4 ) ),
    [ '2', 'x', "1\x{663}", "1\x{FF11}" ],
    'a non-ASCII digit after an ASCII one is not an index either',
  );

  # oracle: 2147483647;2147483648;4294967293;x;4294967296;99999999999;
  # 9007199254740993;18446744073709551616;10000000000;
  my @big = qw(
    x 4294967293 4294967296 99999999999 9007199254740993 2147483648 2147483647
    18446744073709551616 10000000000
  );
  is_deeply(
    $L->keys( Hash::Ordered->new( map { ( $_ => 1 ) } @big ) ),
    [qw( 2147483647 2147483648 4294967293 x 4294967296 99999999999 9007199254740993 18446744073709551616 10000000000 )],
    '2^32 and longer digit strings are not indices, whatever digit they start with',
  );

  # oracle: {"x":1,"1\n":2,"2":3} iterates [2][x][1\n] -- ToString(ToUint32("1\n")) is "1"
  is_deeply( $L->keys( Hash::Ordered->new( x => 1, "1\n" => 2, 2 => 3 ) ), [ '2', 'x', "1\n" ], 'a trailing newline is not an index' );

  # The value readers follow the seam's order.
  my $d = Hash::Ordered->new( b => 'B', 10 => 'T', 9 => 'N' );
  is_deeply( $L->_entries($d), [ [ 9, 'N' ], [ 10, 'T' ], [ 'b', 'B' ] ], '_entries in key order' );
  is_deeply( $L->_values($d), [qw( N T B )], '_values in key order' );
  my @seen;
  $L->async_for( $d, sub { my ( $k, $v, $i, $len, $next ) = @_; push @seen, "$k=$v"; $next->() }, sub { } );
  is_deeply( \@seen, [qw( 9=N 10=T b=B )], 'async_for in key order' );
};

# Maintainer decision on k51 (ADR 0011 amendment): a plain caller hash puts its
# array-index keys first, numerically ascending, and sorts only the rest by key.
subtest 'keys: a plain hash puts array-index keys first, then sorts the rest (ADR 0011, k51)' => sub {
  is_deeply( $L->keys( { b => 1, 10 => 2, 9 => 3, a => 4, 2 => 5 } ), [qw( 2 9 10 a b )], '9 before 10, then a, b' );
  is_deeply(
    $L->keys( { map { ( $_ => 1 ) } qw( a 10 9 01 -1 4294967295 4294967294 1.5 ) } ),
    [qw( 9 10 4294967294 -1 01 1.5 4294967295 a )],
    'non-index keys (01, -1, 1.5, 2^32 - 1) sort as strings after the indices',
  );
  is_deeply( $L->keys( { zeta => 1, alpha => 2, Beta => 3 } ), [qw( Beta alpha zeta )], 'no index keys: plain key sort' );
  is_deeply( $L->_values( { b => 'B', 10 => 'T', 9 => 'N' } ), [qw( N T B )], '_values in key order' );
};

#### js_for_in_keys -- the keys for (k in obj) visits

subtest 'js_for_in_keys: own keys, then the enumerable inherited ones' => sub {
  my $R = 'Text::Nunjucks::Runtime';
  # oracle: 'ab'|safe|dictsort -> length, toString, val, valueOf (sorted); the
  # for-in order is val, length, then SafeString.prototype's valueOf, toString
  is_deeply( $L->js_for_in_keys( $R->SafeString->new('ab') ), [qw( val length valueOf toString )],
    'a SafeString: its prototype adds valueOf and toString' );
  is_deeply( $L->js_for_in_keys( Hash::Ordered->new( b => 1, 1 => 2, a => 3 ) ), [qw( 1 b a )],
    'an ordered dict: keys (Object.prototype has nothing enumerable)' );
  is_deeply( $L->js_for_in_keys( { b => 1, a => 2 } ), [qw( a b )], 'a plain hash: keys' );
  is_deeply( $L->js_for_in_keys( { toString => 1 } ), ['toString'], 'an own toString is just an own key' );
  is_deeply( $L->js_for_in_keys( $R->make_regex( 'a', 'g' ) ), [], 'a regex: nothing' );
  is_deeply( $L->js_for_in_keys(undef), [], 'undefined: nothing' );
};

#### extend / _assign

subtest 'extend / _assign' => sub {
  my $a = { x => 1 };
  my $r = $L->extend( $a, { y => 2 } );
  is( $r, $a, 'returns and mutates the first hash' );
  is_deeply( $a, { x => 1, y => 2 }, 'merged' );

  is_deeply( $L->extend( undef, { z => 3 } ), { z => 3 }, 'undef target -> new hash' );

  # obj2[k] for an ordered dict (a caller's Hash::Ordered context reaches
  # Context's lib.extend({}, ctx)) is read through the seam, not dereferenced
  is_deeply( $L->extend( {}, Hash::Ordered->new( b => 1, 1 => 2 ) ), { b => 1, 1 => 2 }, 'ordered dict source' );

  is( $L->can('_assign'), $L->can('extend'), '_assign is an alias for extend' );
};

#### inOperator

subtest 'in_operator' => sub {
  ok( $L->in_operator( 'b', 'abc' ),      'substring in string' );
  ok( !$L->in_operator( 'z', 'abc' ),     'missing substring' );
  ok( $L->in_operator( 1, [ 1, 2 ] ),     'member of array' );
  ok( !$L->in_operator( '1', [ 1, 2 ] ),  "string '1' not === number 1 in array" );
  ok( $L->in_operator( 'a', { a => 1 } ), 'key of object' );
  ok( !$L->in_operator( 'z', { a => 1 } ), 'missing key' );

  ok( is_bool( $L->in_operator( 'b', 'abc' ) ), 'returns a boolean kind' );

  # F2 regression: JS "hello".indexOf(undefined) searches for "undefined" -> -1
  # -> false. Perl index() would turn undef into "" (matches at 0) and warn.
  ok( $L->in_operator( '', 'hello' ), 'empty string is a substring (present)' );
  my $warned = '';
  local $SIG{__WARN__} = sub { $warned .= $_[0] };
  ok( !$L->in_operator( undef, 'hello' ), 'undef key -> false, JS ToString "undefined" (F2)' );
  is( $warned, '', 'no uninitialized-value warning for undef key (F2)' );

  my $err;
  eval { $L->in_operator( 1, 2 ); 1 } or $err = $@;
  ok( ref($err) && $err->isa('Text::Nunjucks::Lib::Error'), 'unexpected type dies with an Error' );
  is( $err->name, 'Error', 'error name is Error' );
  is( $err->message, 'Cannot use "in" operator to search for "1" in unexpected types.', 'error text' );
};

#### TemplateError + _prettifyError  (messages oracle-confirmed)

subtest 'TemplateError.update' => sub {
  my $te = Text::Nunjucks::Lib::TemplateError->new( 'unknown block tag: foo', 1, 4 );
  is( $te->name,    'Template render error', 'fixed name' );
  is( $te->message, 'unknown block tag: foo', 'raw message before update (parse-mode shape)' );

  $te->update(undef);
  is(
    $te->message,
    "(unknown path) [Line 1, Column 4]\n  unknown block tag: foo",
    'first update adds path + [Line, Column] + 2-space indent'
  );

  my $no_pos = Text::Nunjucks::Lib::TemplateError->new('boom');
  $no_pos->update('page.njk');
  is( $no_pos->message, "(page.njk)\n  boom", 'no lineno -> no [Line] part' );

  my $nested = Text::Nunjucks::Lib::TemplateError->new( 'boom', 2, 5 );
  $nested->update('inner');
  $nested->update('outer');
  is(
    $nested->message,
    "(outer)\n (inner) [Line 2, Column 5]\n  boom",
    'second update: no [Line], single-space indent (include propagation)'
  );
};

subtest '_prettify_error' => sub {
  # foreign error (a JS-style Error) rendered exactly like the oracle
  my $raw = Text::Nunjucks::Lib::Error->new(
    'Cannot use "in" operator to search for "1" in unexpected types.' );
  my $pe = $L->_prettify_error( undef, 0, $raw );
  is( $pe->name, 'Template render error', 'wrapped error takes the render-error name' );
  is(
    $pe->message,
    qq{(unknown path)\n  Error: Cannot use "in" operator to search for "1" in unexpected types.},
    'wrap prepends "Error: " and the (unknown path) prefix'
  );

  # one of ours: not re-wrapped, just updated
  my $ours = Text::Nunjucks::Lib::TemplateError->new( 'unknown block tag: foo', 1, 4 );
  my $pe2  = $L->_prettify_error( 'tmpl.njk', 1, $ours );    # dev flag on -> keep object
  is( $pe2, $ours, 'existing TemplateError is updated in place (dev flag)' );
  is(
    $pe2->message,
    "(tmpl.njk) [Line 1, Column 4]\n  unknown block tag: foo",
    'update applied to our own error'
  );
};

#### JS string seams in UTF-16 code units (ADR 0012)

# The template-level behaviour is pinned by t/corpus/render-strings-utf16.json.
# What the corpus JSON cannot carry is a lone surrogate, so the seams' lone-
# surrogate results are asserted here (each confirmed in node), together with
# the Perl-side contract that a pair spelled as two surrogate characters and
# the astral character are the same JS string.
subtest 'UTF-16 code-unit seams: lone surrogates and both spellings of a pair' => sub {
  my $em     = "\x{1F600}";           # one Perl character, two UTF-16 code units
  my $halves = "\x{D83D}\x{DE00}";    # the same code units, spelled as two characters

  # node: '😀'.charAt(0) / charAt(1) -> '\ud83d' / '\ude00'
  is( $L->js_char_at( $em, 0 ), "\x{D83D}", 'js_char_at inside a pair -> its high surrogate' );
  is( $L->js_char_at( $em, 1 ), "\x{DE00}", 'js_char_at inside a pair -> its low surrogate' );
  # node: 'a😀b'.slice(1, 2) -> '\ud83d'; slice(1, 3) -> '😀'
  is( $L->js_string_slice( "a${em}b", 1, 2 ), "\x{D83D}", 'js_string_slice cutting a pair -> a lone surrogate' );
  is( $L->js_string_slice( "a${em}b", 1, 3 ), $em, 'a slice holding the whole pair comes back as the one character' );

  # node: ('\ud83d' + '\ude00').length -> 2, === '😀' -> true, '😀'.indexOf('\ude00') -> 1
  is( $L->js_string_length($halves), 2, 'js_string_length: two surrogate characters are two code units' );
  is( $L->js_string_compare( $halves, $em ), 0, 'js_string_compare: both spellings are the same string' );
  is( $L->js_string_slice( $halves, 0 ), $em, 'a seam result re-pairs a valid pair into the astral character' );
  is( $L->js_string_index_of( $em, "\x{DE00}" ), 1, 'js_string_index_of finds a lone surrogate inside a pair' );
};

# js_string_append is the one join of two strings (template ~ and +, concat,
# replace, Array join, the output buffer); render cases in the corpus cover
# those callers, this pins the seam itself, lone surrogates included.
subtest 'js_string_append: joins in place, re-pairs at the boundary only' => sub {
  my $em = "\x{1F600}";

  # node: '\ud83d' + '\ude00' === '😀' -> true; ('a\ud83d' + '\ude00b').length -> 4
  my $buf = "a\x{D83D}";
  $L->js_string_append( $buf, "\x{DE00}b" );
  is( $buf, "a${em}b", 'a lone high + lone low surrogate become the astral character' );
  is( CORE::length($buf), 3, '... as one Perl character' );

  my $plain = 'ab';
  is( $L->js_string_append( $plain, 'cd' ), undef, 'returns nothing' );
  is( $plain, 'abcd', 'appends to the caller variable in place' );

  # node: '\ud83d' + '\ud83d', '\ude00' + '\ude00', '\ude00' + '\ud83d' stay two units each
  for my $case (
    [ "\x{D83D}", "\x{D83D}", 'high + high' ],
    [ "\x{DE00}", "\x{DE00}", 'low + low' ],
    [ "\x{DE00}", "\x{D83D}", 'low + high' ],
    [ 'x',        "\x{DE00}", 'a non-surrogate + low' ],
    [ '',         "\x{DE00}", 'an empty buffer + low' ],
    [ "\x{D83D}", '',         'high + an empty string' ],
    [ "\x{D83D}", "x\x{DE00}", 'high + a string whose low surrogate is not first' ],
  ) {
    my ( $l, $r, $label ) = @$case;
    my $b = $l;
    $L->js_string_append( $b, $r );
    is( $b, $l . $r, "$label: plain concatenation" );
  }

  # node: ('\ude00\ud83d' + '\ude00\ud83d').length -> 4, with a valid pair in the middle
  my $lh = "\x{DE00}\x{D83D}";
  $L->js_string_append( $lh, "\x{DE00}\x{D83D}" );
  is( $lh, "\x{DE00}${em}\x{D83D}", 'only the pair at the seam joins; the outer halves stay lone' );
};

subtest 'repeat joins in code units' => sub {
  # node: lib.repeat('\ude00\ud83d', 2) -> de00 d83d de00 d83d, 3 code points
  is( $L->repeat( "\x{DE00}\x{D83D}", 2 ), "\x{DE00}\x{1F600}\x{D83D}",
    'the halves that meet between two repeats form the pair' );
};

#### JS case mapping -- js_to_lower_case / js_to_upper_case

subtest 'js_to_lower_case: Final_Sigma as ICU applies it' => sub {
  # oracle: {{ s | lower }} for each input; Case_Ignorable letters (U+00AD,
  # U+0301, U+0027, U+02B0) are skipped on both sides, a cased letter before
  # and none after makes the sigma final
  my @cases = (
    [ "\x{391}\x{3A3}",                         "\x{3B1}\x{3C2}",                         'ΑΣ -> ας' ],
    [ "\x{391}\x{3A3}.",                        "\x{3B1}\x{3C2}.",                        'before punctuation' ],
    [ "\x{391}\x{3A3}1",                        "\x{3B1}\x{3C2}1",                        'before a digit' ],
    [ "\x{3A3}",                                "\x{3C3}",                                'alone: not final' ],
    [ "\x{391}\x{3A3} \x{392}",                 "\x{3B1}\x{3C2} \x{3B2}",                 'before a space and a word' ],
    [ "\x{391}\x{3A3}\x{391}",                  "\x{3B1}\x{3C3}\x{3B1}",                  'inside a word' ],
    [ "\x{391}.\x{3A3}",                        "\x{3B1}.\x{3C2}",                        'after punctuation (Case_Ignorable)' ],
    [ "\x{391}\x{3A3}\x{AD}\x{391}",            "\x{3B1}\x{3C3}\x{AD}\x{3B1}",            'soft hyphen skipped after' ],
    [ "\x{391}\x{AD}\x{3A3}",                   "\x{3B1}\x{AD}\x{3C2}",                   'soft hyphen skipped before' ],
    [ "\x{391}\x{301}\x{3A3}\x{301}\x{391}",    "\x{3B1}\x{301}\x{3C3}\x{301}\x{3B1}",    'combining marks skipped' ],
    [ "1\x{3A3}",                               "1\x{3C3}",                               'after a digit: not final' ],
    [ "\x{391}'\x{3A3}'",                       "\x{3B1}'\x{3C2}'",                       'apostrophes skipped' ],
    [ "\x{1C5}\x{3A3}",                         "\x{1C6}\x{3C2}",                         'after a titlecase letter' ],
    [ "\x{2B0}\x{3A3}",                         "\x{2B0}\x{3C3}",                         'U+02B0 is cased and ignorable: not a cased letter before' ],
    [ "\x{391}\x{3A3}\x{3A3}",                  "\x{3B1}\x{3C3}\x{3C2}",                  'only the last of two' ],
    [ "\x{10400}\x{3A3}",                       "\x{10428}\x{3C2}",                       'after an astral cased letter' ],
    [ "\x{3A3}\x{10400}",                       "\x{3C3}\x{10428}",                       'before an astral cased letter' ],
    [ "\x{391}\x{3A3}\x{1F600}",                "\x{3B1}\x{3C2}\x{1F600}",                'before an emoji' ],
  );
  for my $case (@cases) {
    my ( $in, $want, $label ) = @$case;
    is( $L->js_to_lower_case($in), $want, $label );
  }
};

subtest 'js_to_upper_case / js_to_lower_case: special casing and encodings' => sub {
  # oracle: {{ s | upper }}, {{ s | lower }}, {{ ('İ' | lower) | length }} -> 2
  is( $L->js_to_upper_case("\x{DF}"), 'SS', 'ß -> SS' );
  is( $L->js_to_upper_case("\x{FB01}\x{149}\x{1F0}"), "FI\x{2BC}NJ\x{30C}", 'ﬁ ŉ ǰ expand' );
  is( $L->js_to_upper_case("\x{390}"), "\x{399}\x{308}\x{301}", 'ΐ expands to three' );
  is( $L->js_to_lower_case("\x{130}"), "i\x{307}", 'İ -> i + combining dot' );
  is( $L->js_to_upper_case("\x{1C5}"), "\x{1C4}", 'titlecase ǅ -> Ǆ' );
  is( $L->js_to_upper_case("\x{10428}\x{10400}"), "\x{10400}\x{10400}", 'astral Deseret upper' );
  is( $L->js_to_lower_case("\x{10428}\x{10400}"), "\x{10428}\x{10428}", 'astral Deseret lower' );

  # a native 8-bit string still maps by Unicode rules (unicode_strings)
  my $latin1 = "\xDF\xE9\xFF\xB5";
  ok( !utf8::is_utf8($latin1), 'the input is a native 8-bit string' );
  is( $L->js_to_upper_case($latin1), "SS\x{C9}\x{178}\x{39C}", 'ßéÿµ -> SSÉŸΜ' );
  is( $L->js_to_lower_case("\xC9\xDE"), "\x{E9}\x{FE}", 'ÉÞ -> éþ' );

  # ADR 0012: a lone surrogate maps to itself, two halves spelled as two
  # characters are the pair
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is( $L->js_to_upper_case("\x{D83D}"), "\x{D83D}", 'a lone high surrogate stays' );
  is( $L->js_to_lower_case("x\x{DE00}"), "x\x{DE00}", 'a lone low surrogate stays' );
  is( $L->js_to_upper_case("\x{D801}\x{DC28}"), "\x{10400}", 'a pair spelled as two halves maps as its character' );
  is_deeply( \@warnings, [], 'no surrogate warning' );
};

#### GetSubstitution -- js_get_substitution

subtest 'js_get_substitution: the JS replacement patterns' => sub {
  # oracle: 'abc'|replace(r/b/, ...) and the other templates cited per line;
  # the result here is what replaces the match, so 'a' . $result . 'c' is the
  # rendered output
  is( $L->js_get_substitution( 'b', 'abc', 1, [], undef, 'plain' ), 'plain', 'no $: as is' );
  is( $L->js_get_substitution( 'b', 'abc', 1, [], undef, q{[$&][$`][$'][$$][$][$x][$<n>][$1]} ),
    q{[b][a][c][$][$][$x][$<n>][$1]},
    q{$& $` $' $$; a lone $, $x, $<n> without groups and $1 without captures stay} );
  is( $L->js_get_substitution( 'b', 'abc', 1, ['b'], undef, q{[$1$2$0$01$10]} ), q{[b$2$0bb0]},
    'r/(b)/: $2 and $0 stay, $01 is $1, $10 is $1 then 0' );

  # 'abcdefghijkl'|replace(r/(a)(b)...(k)/, '[$11|$10|$1|$12|$011|$00|$100]')
  my @caps = map { chr( ord('a') + $_ ) } 0 .. 10;
  is( $L->js_get_substitution( 'abcdefghijk', 'abcdefghijkl', 0, \@caps, undef, q{[$11|$10|$1|$12|$011|$00|$100]} ),
    q{[k|j|a|a2|a1|$00|j0]}, 'two digits when the group exists, else one digit and a literal' );

  # 'ab'|replace(r/(a)|(z)/, '[$1|$2]') -> '[a|]b'
  is( $L->js_get_substitution( 'a', 'ab', 0, [ 'a', undef ], undef, q{[$1|$2]} ), q{[a|]},
    'a group that did not take part is empty' );

  # 'abc'|replace(r/(?<n>b)/, '[$<n>$<m>]') -> 'a[b]c'; '$<n' without '>' stays
  is( $L->js_get_substitution( 'b', 'abc', 1, ['b'], Hash::Ordered->new( n => 'b' ), q{[$<n>$<m>][$<n]} ),
    q{[b][$<n]}, 'named groups; an unknown name is empty, an unclosed one literal' );

  # '😀ab😀b'|replace(r/b/g, '[$`]') -> '😀a[😀a]😀[😀ab😀]': positions in code units
  is( $L->js_get_substitution( 'b', "\x{1F600}ab\x{1F600}b", 3, [], undef, q{[$`|$']} ),
    "[\x{1F600}a|\x{1F600}b]", '$` and $\' cut at a code-unit position' );
};

# oracle: [1,2,3,4,5]|slice(2.5) -> [[1,2],[3,4],[5]] (Math.floor(5 / 2.5) = 2);
# Math.floor on NaN, -0, +-Infinity and negatives as IEEE floor
subtest 'js_math_floor (Math.floor)' => sub {
  my $inf = 9**9**9;
  is( $L->js_math_floor(2.5),  2,  'positive fraction' );
  is( $L->js_math_floor(-2.5), -3, 'negative fraction rounds down' );
  is( $L->js_math_floor(3),    3,  'an integer is itself' );
  is( $L->number_to_string( $L->js_math_floor( $inf / $inf ) ), 'NaN',       'NaN' );
  is( $L->number_to_string( $L->js_math_floor($inf) ),          'Infinity',  'Infinity' );
  is( $L->number_to_string( $L->js_math_floor( -$inf ) ),       '-Infinity', '-Infinity' );
  is( sprintf( '%g', $L->js_math_floor(-0.0) ), '-0', '-0 stays -0' );
};

subtest 'js_word_class is ASCII' => sub {
  # oracle: 'héllo wörld'|wordcount -> 4, '١٢٣ abc'|wordcount -> 1
  my $w = $L->js_word_class;
  is( scalar( () = "h\x{E9}llo w\x{F6}rld" =~ /(?:$w)+/g ), 4, 'é and ö split words' );
  is( scalar( () = "\x{661}\x{662}\x{663} abc" =~ /(?:$w)+/g ), 1, 'Arabic-Indic digits are not word characters' );
  ok( '_' =~ /\A$w\z/, 'the underscore is' );
  ok( "\x{17F}" !~ /\A$w\z/, 'ſ is not' );
};

subtest 'js_digit_class is ASCII' => sub {
  # oracle: 'a@x3.com'|urlize is a mailto: link, the same with ARABIC-INDIC
  # DIGIT THREE (U+0663) for the 3 is not
  my $d = $L->js_digit_class;
  ok( '7' =~ /\A$d\z/,       'an ASCII digit is' );
  ok( "\x{663}" !~ /\A$d\z/, 'U+0663 is not' );
  ok( "\x{FF11}" !~ /\A$d\z/, 'FULLWIDTH DIGIT ONE is not' );
};

# Math.ceil / Math.round / Math.abs over a Number; oracle: 4.5|round is 5,
# -0.5|round(0) and -0.4|round(0, 'ceil') are -0 (1 / x is -Infinity), (-0)|abs
# is +0 (1 / x is Infinity)
subtest 'js_math_ceil / js_math_round / js_math_abs (Math.ceil, Math.round, Math.abs)' => sub {
  my $inf = 9**9**9;
  my $nan = $inf - $inf;
  my $s   = sub { $L->number_to_string( $_[0] ) };
  is( $L->js_math_ceil(2.1),  3,  'ceil: up' );
  is( $L->js_math_ceil(-2.9), -2, 'ceil: negative up' );
  is( sprintf( '%g', $L->js_math_ceil(-0.4) ), '-0', 'ceil: -0.4 is -0' );
  is( $s->( $L->js_math_ceil($nan) ), 'NaN', 'ceil: NaN' );

  is( $L->js_math_round(2.5),  3,  'round: a tie goes up' );
  is( $L->js_math_round(-2.5), -2, 'round: a negative tie goes towards +Infinity' );
  is( $L->js_math_round(2.4),  2,  'round: below the tie' );
  is( $L->js_math_round(0.49999999999999994), 0, 'round: the largest double below 0.5 is 0, never x + 0.5' );
  is( $s->( $L->js_math_round(4503599627370497) ), '4503599627370497', 'round: an odd integer above 2^52 is itself' );
  is( sprintf( '%g', $L->js_math_round(-0.5) ), '-0', 'round: -0.5 is -0' );
  is( sprintf( '%g', $L->js_math_round(-0.0) ), '-0', 'round: -0 stays -0' );
  is( $s->( $L->js_math_round($nan) ),    'NaN',       'round: NaN' );
  is( $s->( $L->js_math_round( -$inf ) ), '-Infinity', 'round: -Infinity' );

  is( $L->js_math_abs(-3.5), 3.5, 'abs' );
  is( sprintf( '%g', $L->js_math_abs(-0.0) ), '0', 'abs: -0 is +0' );
  is( $s->( $L->js_math_abs( -$inf ) ), 'Infinity', 'abs: -Infinity' );
  is( $s->( $L->js_math_abs($nan) ),    'NaN',      'abs: NaN' );
};

# Math.pow; oracle: 1 ** (1/0), (-1) ** (1/0) and 1 ** NaN are NaN, NaN ** 0
# is 1
subtest 'js_math_pow (Math.pow)' => sub {
  my $inf = 9**9**9;
  my $nan = $inf - $inf;
  my $s   = sub { $L->number_to_string( $_[0] ) };
  is( $s->( $L->js_math_pow( 10, 2 ) ),     '100',      '10 ** 2' );
  is( $s->( $L->js_math_pow( 10, -2 ) ),    '0.01',     '10 ** -2' );
  is( $s->( $L->js_math_pow( 1, $inf ) ),   'NaN',      '1 ** Infinity' );
  is( $s->( $L->js_math_pow( -1, -$inf ) ), 'NaN',      '-1 ** -Infinity' );
  is( $s->( $L->js_math_pow( 1, $nan ) ),   'NaN',      '1 ** NaN' );
  is( $s->( $L->js_math_pow( $nan, 0 ) ),   '1',        'NaN ** 0' );
  is( $s->( $L->js_math_pow( 2, $inf ) ),   'Infinity', '2 ** Infinity' );
};

# parseInt(string, radix) over a string and a Number radix (undef: undefined);
# every expected value is node's String(parseInt(s, radix)), -0 spelt '-0'
subtest 'js_parse_int (parseInt)' => sub {
  my $nan = 9**9**9 - 9**9**9;
  my $show = sub { my ($n) = @_; ( $n == 0 && sprintf( '%g', $n ) eq '-0' ) ? '-0' : $L->number_to_string($n) };
  for my $c (
    [ "42", undef, '42' ],
    [ "  -42px", undef, '-42' ],
    [ "+7", undef, '7' ],
    [ "\x{A0}\x{FEFF} 12", undef, '12' ],
    [ "\x{180E}12", undef, 'NaN' ],
    [ "0x1A", undef, '26' ],
    [ "0x1A", 16, '26' ],
    [ "0x1A", 10, '0' ],
    [ "1A", 16, '26' ],
    [ "0x", undef, 'NaN' ],
    [ "-0x10", undef, '-16' ],
    [ "101", 2, '5' ],
    [ "777", 8, '511' ],
    [ "zz", 36, '1295' ],
    [ "Zz", 36, '1295' ],
    [ "12", 37, 'NaN' ],
    [ "12", 1, 'NaN' ],
    [ "12", 0, '12' ],
    [ "12", -1, 'NaN' ],
    [ "12", 4294967306, '12' ],
    [ "12", 16.9, '18' ],
    [ "12", $nan, '12' ],
    [ "-0", undef, '-0' ],
    [ "-0x0", undef, '-0' ],
    [ "", undef, 'NaN' ],
    [ "abc", undef, 'NaN' ],
    [ "3.9", undef, '3' ],
    [ "1e21", undef, '1' ],
    [ "9007199254740993", undef, '9007199254740992' ],
    [ "123456789012345678901234567890", undef, '1.2345678901234568e+29' ],
    [ "1" . ( "0" x 52 ) . "10", 2, '18014398509481984' ],
    [ "1" . ( "0" x 52 ) . "11", 2, '18014398509481988' ],
    [ "1" . ( "0" x 52 ) . "101", 2, '36028797018963976' ],
    [ ( "f" x 18 ), 16, '4.722366482869645e+21' ],
    [ ( "z" x 16 ), 36, '7.958661109946401e+24' ],
    [ ( "7" x 21 ), 8, '9223372036854776000' ],
    [ ( "1" x 400 ), undef, 'Infinity' ],
    [ "\x{FF11}\x{FF12}", undef, 'NaN' ],
    [ "\x{663}", undef, 'NaN' ],
  ) {
    my ( $str, $radix, $want ) = @$c;
    is( $show->( $L->js_parse_int( $str, $radix ) ), $want,
      'parseInt(' . ( length($str) > 30 ? substr( $str, 0, 30 ) . '...' : $str ) =~ s/([^\x20-\x7e])/sprintf('\\u%04X', ord $1)/ger
        . ', ' . ( defined $radix ? $radix : 'undefined' ) . ')' );
  }
};

# parseFloat(string); every expected value is node's String(parseFloat(s))
subtest 'js_parse_float (parseFloat)' => sub {
  my $show = sub { my ($n) = @_; ( $n == 0 && sprintf( '%g', $n ) eq '-0' ) ? '-0' : $L->number_to_string($n) };
  for my $c (
    [ "3.5", '3.5' ],
    [ "  -3.5abc", '-3.5' ],
    [ ".5", '0.5' ],
    [ "5.", '5' ],
    [ "1e3", '1000' ],
    [ "1e", '1' ],
    [ "1e+", '1' ],
    [ "-.5e-3x", '-0.0005' ],
    [ "0x10", '0' ],
    [ "Infinity", 'Infinity' ],
    [ "-Infinityx", '-Infinity' ],
    [ "infinity", 'NaN' ],
    [ "+Infinity", 'Infinity' ],
    [ "Inf", 'NaN' ],
    [ "-0", '-0' ],
    [ "", 'NaN' ],
    [ "abc", 'NaN' ],
    [ "1_000", '1' ],
    [ "\x{2028}\x{3000} 2.5", '2.5' ],
    [ "\x{85} 1", 'NaN' ],
    [ "2.4703282292062328e-324", '5e-324' ],
    [ "1.7976931348623159e308", 'Infinity' ],
    [ "9007199254740993", '9007199254740992' ],
    [ "1" . ( "0" x 400 ), 'Infinity' ],
  ) {
    my ( $str, $want ) = @$c;
    is( $show->( $L->js_parse_float($str) ), $want,
      'parseFloat(' . ( length($str) > 30 ? substr( $str, 0, 30 ) . '...' : $str ) =~ s/([^\x20-\x7e])/sprintf('\\u%04X', ord $1)/ger . ')' );
  }
};

subtest '_js_to_int32 (ToInt32)' => sub {
  my $inf = 9**9**9;
  is( $L->_js_to_int32(undef),         0,           'undefined' );
  is( $L->_js_to_int32( $inf - $inf ), 0,           'NaN' );
  is( $L->_js_to_int32($inf),          0,           'Infinity' );
  is( $L->_js_to_int32(16.9),          16,          'truncates' );
  is( $L->_js_to_int32(-1),            -1,          'a negative stays' );
  is( $L->_js_to_int32(2147483648),    -2147483648, '2^31 wraps negative' );
  is( $L->_js_to_int32(4294967306),    10,          'modulo 2^32' );
};

# encodeURIComponent; every expected value is node's encodeURIComponent(s)
subtest 'js_encode_uri_component (encodeURIComponent)' => sub {
  for my $c (
    [ "abc", 'abc' ],
    [ "A-Z a-z 0-9 -_.!~*'()", 'A-Z%20a-z%200-9%20-_.!~*\'()' ],
    [ "a+b=c/d?e#f;g,h:i\@j\$k&l", 'a%2Bb%3Dc%2Fd%3Fe%23f%3Bg%2Ch%3Ai%40j%24k%26l' ],
    [ "\x{E9}\x{20AC}\x{1F600}", '%C3%A9%E2%82%AC%F0%9F%98%80' ],
    [ "\x{0}\x{7F}\x{80}\x{7FF}\x{800}\x{FFFD}", '%00%7F%C2%80%DF%BF%E0%A0%80%EF%BF%BD' ],
  ) {
    my ( $str, $want ) = @$c;
    is( $L->js_encode_uri_component($str), $want, 'encodeURIComponent: ' . $want );
  }
  is( $L->js_encode_uri_component("\x{D83D}\x{DE00}"), '%F0%9F%98%80', 'a pair spelt as two surrogates is one character' );
  for my $lone ( "\x{D83D}", "a\x{DE00}", "\x{DE00}\x{D83D}" ) {
    my $err = do { local $@; eval { $L->js_encode_uri_component($lone); 1 } ? undef : $@ };
    ok( $err && $err->isa('Text::Nunjucks::Lib::Error'), 'a lone surrogate throws' );
    is( $err && $err->name,    'URIError',      '... a URIError' );
    is( $err && $err->message, 'URI malformed', '... URI malformed (oracle: "\u{1F600}"|first|urlencode)' );
  }
};

#### js_json_stringify -- JSON.stringify(value, null, space) for the dump filter

# Every expectation below was measured with the oracle through dump
# (maint/oracle.js); a macro stood in for the toJSON functions.
subtest 'js_json_stringify: values' => sub {
  my $R   = 'Text::Nunjucks::Runtime';
  my $inf = 9**9**9;
  my $nan = $inf - $inf;
  is( $L->js_json_stringify(undef), undef, 'undefined -> undefined' );
  is( $L->js_json_stringify( $R->None ), 'null', 'null' );
  is( $L->js_json_stringify(true) . $L->js_json_stringify(false), 'truefalse', 'booleans' );
  is( $L->js_json_stringify( "a\"b\\c/\n\t\r\b\f\x01\x1f\x7f\x{2028}\x{1F600}" ),
    '"a\\"b\\\\c/\\n\\t\\r\\b\\f\\u0001\\u001f' . "\x7f\x{2028}\x{1F600}" . '"',
    'QuoteJSONString: the short escapes, \\u00XX below 0x20, the rest as is' );
  is( $L->js_json_stringify("\x{D83D}") . $L->js_json_stringify("\x{DE00}"), '"\\ud83d""\\ude00"',
    'a lone surrogate is escaped (well-formed JSON.stringify)' );
  # ADR 0012: a caller string spelling a pair as two surrogate characters is the
  # same JS string as the one astral character -- both dump the pair as is
  # (oracle: 'a😀b'|dump -> "a😀b", a context hash {"a😀b": 1}|dump -> {"a😀b":1})
  is( $L->js_json_stringify("a\x{D83D}\x{DE00}b"), qq("a\x{1F600}b"), 'a pair spelled as two surrogates: a value' );
  is( $L->js_json_stringify("a\x{1F600}b"),        qq("a\x{1F600}b"), '... the same as the one character' );
  is( $L->js_json_stringify( { "a\x{D83D}\x{DE00}b" => 1 } ), qq({"a\x{1F600}b":1}), '... a key' );
  is( $L->js_json_stringify( { "a\x{1F600}b" => 1 } ),        qq({"a\x{1F600}b":1}), '... the same as the one character' );
  is( $L->js_json_stringify("\x{DE00}\x{D83D}"), '"\\ude00\\ud83d"', 'a low then a high surrogate is no pair: both escaped' );
  is( $L->js_json_stringify( [ 1.5, -0.0, 0.30000000000000004, 1e21, -1e-7, $inf, -$inf, $nan ] ),
    '[1.5,0,0.30000000000000004,1e+21,-1e-7,null,null,null]', 'numbers: Number::toString, non-finite -> null' );
  is( $L->js_json_stringify( sub { } ), undef, 'a function -> undefined' );
  is( $L->js_json_stringify( [ sub { }, 1 ] ), '[null,1]', '... null in an array' );
  is( $L->js_json_stringify( Hash::Ordered->new( a => sub { }, b => 1 ) ), '{"b":1}', '... left out of an object' );
  is( $L->js_json_stringify( [ undef, 1 ] ), '[null,1]', 'undefined: null in an array' );
  is( $L->js_json_stringify( Hash::Ordered->new( a => undef, b => 1 ) ), '{"b":1}', '... left out of an object' );
  is( $L->js_json_stringify( $R->SafeString->new('ab') ), '{"val":"ab","length":2}',
    'a SafeString is no String wrapper: its own val and length' );
  is( $L->js_json_stringify( $R->make_regex( 'a', 'g' ) ), '{}', 'a regex: lastIndex is not enumerable' );
  is( $L->js_json_stringify( [ $R->make_regex( 'a', '' ) ] ), '[{}]', '... in an array' );
  is( $L->js_json_stringify( Hash::Ordered->new( a => [ 1, Hash::Ordered->new( b => $R->None ) ], c => {} ) ),
    '{"a":[1,{"b":null}],"c":{}}', 'nested' );
  my $a = [1];
  is( $L->js_json_stringify( [ $a, $a ] ), '[[1],[1]]', 'a shared value is no circle' );

  # toJSON(key): the property key, '' at the top, an index as a string
  my @seen;
  my $to_json = sub { push @seen, $_[0]; 'K' . $_[0] . 'K' };
  is( $L->js_json_stringify( [ { toJSON => $to_json }, { x => { toJSON => $to_json } } ] ), '["K0K",{"x":"KxK"}]',
    'toJSON gets the key' );
  is( $L->js_json_stringify( { toJSON => $to_json } ), '"KK"', '... the empty key at the top' );
  ok( builtin::created_as_string( $seen[0] ), '... an index key is a string' );
  is( $L->js_json_stringify( Hash::Ordered->new( toJSON => 5, a => 1 ) ), '{"toJSON":5,"a":1}',
    'a toJSON that is no function is a plain property' );
};

subtest 'js_json_stringify: the gap (V8 InitializeGap)' => sub {
  my $R   = 'Text::Nunjucks::Runtime';
  my $inf = 9**9**9;
  is( $L->js_json_stringify( Hash::Ordered->new( a => [ 1, {} ], b => {}, c => [] ), 2 ),
    qq({\n  "a": [\n    1,\n    {}\n  ],\n  "b": {},\n  "c": []\n}), '2: indent and ": ", empty containers stay closed' );
  is( $L->js_json_stringify( [1], 2.9 ), qq([\n  1\n]),           '2.9: truncated' );
  is( $L->js_json_stringify( [1], 11 ),  qq([\n          1\n]),   '11: at most 10' );
  is( $L->js_json_stringify( [1], $inf ), qq([\n          1\n]),  'Infinity: 10' );
  is( $L->js_json_stringify( [1], $_ ), '[1]', "$_: no gap" ) for -1, 0;
  is( $L->js_json_stringify( [1], 0.5 ), qq([\n1\n]), '0.5: an empty gap that still breaks lines (V8, not the spec)' );
  is( $L->js_json_stringify( Hash::Ordered->new( a => 1 ), 0.5 ), qq({\n"a": 1\n}), '... and still writes ": "' );
  is( $L->js_json_stringify( [1], 'abcdefghijkl' ), qq([\nabcdefghij1\n]), 'a string: its first 10 code units' );
  is( $L->js_json_stringify( [1], '' ), '[1]', "'': no gap" );
  is( $L->js_json_stringify( Hash::Ordered->new( a => 1 ), '-' ), qq({\n-"a": 1\n}), "'-'" );
  is( $L->js_json_stringify( [1], 'x' . "\x{1F600}" x 5 ), "[\nx" . "\x{1F600}" x 4 . "\x{D83D}1\n]",
    '10 code units can cut a pair in half (ADR 0012)' );
  is( $L->js_json_stringify( [1], $_ ), '[1]', 'no gap: ' . ( ref($_) || $_ ) )
    for $R->SafeString->new('  '), true, $R->None, [2], $inf - $inf;
};

subtest 'js_json_stringify: the V8 circular-structure message' => sub {
  my $head = 'TypeError: Converting circular structure to JSON';
  my $a    = [];
  push @$a, $a;
  is( thrown( sub { $L->js_json_stringify($a) } ),
    "$head\n    --> starting at object with constructor 'Array'\n    --- index 0 closes the circle", 'self' );

  my $x = [];
  my $o = { x => $x };
  push @$x, $o;
  is( thrown( sub { $L->js_json_stringify($o) } ),
    "$head\n    --> starting at object with constructor 'Object'\n"
      . "    |     property 'x' -> object with constructor 'Array'\n    --- index 0 closes the circle",
    'an object, through a property' );

  # d -> '' -> c -> 0 -> b -> k -> a -> 0 -> d
  my $chain = sub {
    my $ca = [];
    my $cb = { k => $ca };
    my $cc = [$cb];
    my $cd = { '' => $cc };
    return ( $ca, $cd );
  };
  my ( $ca, $cd ) = $chain->();
  push @$ca, $cd;
  is( thrown( sub { $L->js_json_stringify($cd) } ),
    "$head\n    --> starting at object with constructor 'Object'\n"
      . "    |     <anonymous> -> object with constructor 'Array'\n"
      . "    |     index 0 -> object with constructor 'Object'\n"
      . "    |     property 'k' -> object with constructor 'Array'\n    --- index 0 closes the circle",
    'four levels: every line, the empty key as <anonymous>' );

  ( $ca, $cd ) = $chain->();
  my $e = [ 0, $cd ];
  push @$ca, $e;
  is( thrown( sub { $L->js_json_stringify($e) } ),
    "$head\n    --> starting at object with constructor 'Array'\n"
      . "    |     index 1 -> object with constructor 'Object'\n"
      . "    |     <anonymous> -> object with constructor 'Array'\n    |     ...\n"
      . "    |     property 'k' -> object with constructor 'Array'\n    --- index 0 closes the circle",
    'five levels: two lines, ..., the last one' );

  ( $ca, $cd ) = $chain->();
  $e = [ 0, $cd ];
  my $f = { 0 => $e };
  push @$ca, $f;
  is( thrown( sub { $L->js_json_stringify($f) } ),
    "$head\n    --> starting at object with constructor 'Object'\n"
      . "    |     property '0' -> object with constructor 'Array'\n"
      . "    |     index 1 -> object with constructor 'Object'\n    |     ...\n"
      . "    |     property 'k' -> object with constructor 'Array'\n    --- index 0 closes the circle",
    "an object's integer key is a property, not an index" );

  my $ia = [];
  my $ib = [$ia];
  my $ic = { z => $ib };
  push @$ia, $ib;
  is( thrown( sub { $L->js_json_stringify($ic) } ),
    "$head\n    --> starting at object with constructor 'Array'\n"
      . "    |     index 0 -> object with constructor 'Array'\n    --- index 0 closes the circle",
    'the circle starts below the top' );
};

#### js_array_sort -- V8's Array.prototype.sort (decision B, k17)

# t/data/js-array-sort.json is written by maint/js-array-sort-fixtures with the
# oracle's node (V8 13.6.233.17): every comparator call V8 made, as element
# ids in call order, and the sorted ids -- a long sequence as count + digest.
# The comparator names are implemented here with the same results as there.
# The call sequence is the strong pin: for an inconsistent comparator it is
# what decides the result.
my $SORT_FIXTURES = do {
  my $file = Path::Tiny::path(__FILE__)->parent->child( 'data', 'js-array-sort.json' );
  # allow_bignum: on a perl with a 4-byte IV an integer like 9007199254740992 would
  # otherwise decode as a string; sort_fixture_value turns a bignum or bigfloat into a double
  # (ADR 0019).
  JSON::MaybeXS->new( utf8 => 1, allow_bignum => 1 )->decode( $file->slurp_raw );
};

sub sort_digest {
  my ($seq) = @_;
  my $h = 0;
  $h = ( $h * 31 + $_ + 1 ) % 4294967296 for @$seq;
  return $h;
}

my $JS_NONE = 'Text::Nunjucks::Runtime'->None;
my %SORT_COMPARATOR = (
  'numeric'           => sub { sub { $_[0]{key} - $_[1]{key} } },
  'numeric-desc'      => sub { sub { $_[1]{key} - $_[0]{key} } },
  'mod5'              => sub { sub { POSIX::fmod( $_[0]{key}, 5 ) - POSIX::fmod( $_[1]{key}, 5 ) } },    # JS %: sign of the dividend
  'fraction'          => sub { sub { ( $_[0]{key} - $_[1]{key} ) / 1024 } },
  'neg-zero'          => sub { sub { $_[0]{key} == $_[1]{key} ? -0.0 : $_[0]{key} - $_[1]{key} } },
  'string-result'     => sub { sub { $L->number_to_string( $_[0]{key} - $_[1]{key} ) } },
  'whitespace-result' => sub { sub { " \n" . $L->number_to_string( $_[0]{key} - $_[1]{key} ) . "\t " } },
  'array-result'      => sub { sub { [ $_[0]{key} - $_[1]{key} ] } },
  'null-result'       => sub { sub { $_[0]{key} < $_[1]{key} ? -1 : $_[0]{key} > $_[1]{key} ? 1 : $JS_NONE } },
  'undefined-result'  => sub { sub { $_[0]{key} < $_[1]{key} ? -1 : $_[0]{key} > $_[1]{key} ? undef : 0 } },
  'gt-boolean'        => sub { sub { $_[0]{key} > $_[1]{key} ? true : false } },
  'sign-flip'         => sub { sub { $_[0]{key} < $_[1]{key} ? -1 : 1 } },
  'nan-result'        => sub { sub { 'x' } },
  'hash3'             => sub { sub { ( ( $_[0]{id} * 7919 + $_[1]{id} * 104729 + 12345 ) % 3 ) - 1 } },
  'minstd'     => sub { my ($s) = @_; sub { $s = ( $s * 48271 ) % 2147483647; ( $s % 3 ) - 1 } },
  'minstd-neg' => sub { my ($s) = @_; sub { $s = ( $s * 48271 ) % 2147483647; $s % 8 == 0 ? 1 : -1 } },
  'minstd-pos' => sub { my ($s) = @_; sub { $s = ( $s * 48271 ) % 2147483647; $s % 8 == 0 ? -1 : 1 } },
);

# The tagged element form of the fixture (see maint/js-array-sort-fixtures).
my $SORT_INF = 9**9**9;
sub sort_fixture_value {
  my ($v) = @_;
  return $JS_NONE unless defined $v;
  return ( $v ? true : false ) if JSON::MaybeXS::is_bool($v);
  return [ map { sort_fixture_value($_) } @$v ] if ref $v eq 'ARRAY';
  return unpack( 'd', pack( 'd', $v->numify ) ) if Scalar::Util::blessed($v) && ( $v->isa('Math::BigInt') || $v->isa('Math::BigFloat') );
  if ( ref $v eq 'HASH' ) {
    my $t = $v->{'$'};
    return $t eq 'undefined' ? undef
      : $t eq 'NaN'       ? $SORT_INF - $SORT_INF
      : $t eq 'Infinity'  ? $SORT_INF
      : $t eq '-Infinity' ? -$SORT_INF
      : $t eq '-0'        ? -0.0
      : $t eq 'object'    ? {}
      :                     die "unknown fixture tag $t";
  }
  return $v;
}

sub sort_fixture_tag {
  my ($v) = @_;
  return 'u' unless defined $v;
  return 'l' if 'Text::Nunjucks::Runtime'->_is_none($v);
  return 'b:' . ( $v ? 'true' : 'false' ) if is_bool($v);
  if ( builtin::created_as_number($v) ) {
    return 'n:-0' if $v == 0 && sprintf( '%g', $v ) eq '-0';
    return 'n:' . $L->number_to_string($v);
  }
  return 's:' . $v unless ref $v;
  return 'a[' . join( ',', map { sort_fixture_tag($_) } @$v ) . ']' if ref $v eq 'ARRAY';
  return 'o';
}

subtest 'js_array_sort: the fixture is the pinned V8' => sub {
  like( $SORT_FIXTURES->{v8}, qr/\A13\.6\.233\.17(?:-|\z)/, 'generated with V8 13.6.233.17 (' . $SORT_FIXTURES->{node} . ')' );
  cmp_ok( scalar @{ $SORT_FIXTURES->{cases} }, '>', 900, 'and it has its cases' );
};

subtest 'js_array_sort: comparator call sequence and result match V8' => sub {
  for my $case ( grep { defined $_->{comparator} } @{ $SORT_FIXTURES->{cases} } ) {
    my $input = $case->{input};
    my @arr   = map { defined $input->[$_] ? { id => $_, key => $input->[$_] } : undef } 0 .. $#$input;
    my $cmp   = $SORT_COMPARATOR{ $case->{comparator} }->( $case->{seed} );
    my @calls;
    my $recording = sub {
      push @calls, map { defined $_ ? $_->{id} : -1 } @_[ 0, 1 ];
      return $cmp->(@_);
    };
    my $ret = eval { $L->js_array_sort( \@arr, $recording ) };
    my $err = $@;
    my @ids = map { defined $_ ? $_->{id} : undef } @arr;
    my $ok  = !$err
      && $ret == \@arr
      && @calls / 2 == $case->{calls_count}
      && sort_digest( \@calls ) == $case->{calls_digest}
      && ( defined $case->{result}
        ? join( ',', map { $_ // 'u' } @ids ) eq join( ',', map { $_ // 'u' } @{ $case->{result} } )
        : sort_digest( [ map { $_ // -1 } @ids ] ) == $case->{result_digest} );
    ok( $ok, $case->{name} ) or do {
      diag( 'died: ' . $err ) if $err;
      diag( 'calls: ' . ( @calls / 2 ) . ' (V8 ' . $case->{calls_count} . ')' );
      is_deeply( \@calls, $case->{calls}, '... the call sequence' ) if $case->{calls};
      is_deeply( \@ids, $case->{result}, '... the result' ) if $case->{result};
    };
  }
};

subtest 'js_array_sort: the default comparator over mixed kinds matches V8' => sub {
  for my $case ( grep { !defined $_->{comparator} } @{ $SORT_FIXTURES->{cases} } ) {
    my @arr = map { sort_fixture_value($_) } @{ $case->{input} };
    $L->js_array_sort( \@arr );
    is_deeply( [ map { sort_fixture_tag($_) } @arr ], $case->{result}, $case->{name} );
  }
};

# What the fixture cannot carry, each measured in node (V8 13.6.233.17).
subtest 'js_array_sort: the receiver, comparator exceptions, the spec prelude' => sub {
  my $arr = [ 3, 1, 2 ];
  my @seen;
  $L->js_array_sort( $arr, sub { push @seen, join( ',', @$arr ); $_[0] - $_[1] } );
  is_deeply( \@seen, [ ('3,1,2') x 4 ], 'the comparator sees the unsorted receiver: it is written once, at the end' );
  is( join( ',', @$arr ), '1,2,3', '... and then sorted' );

  my $boom = bless {}, 'Some::Exception';
  $arr = [ 5, 4, 3, 2, 1 ];
  my $k   = 0;
  my $err = do { local $@; eval { $L->js_array_sort( $arr, sub { die $boom if ++$k == 4; $_[0] - $_[1] } ); 1 } ? undef : $@ };
  ok( defined $err && $err == $boom, 'whatever the comparator throws propagates as is' );
  is( join( ',', @$arr ), '5,4,3,2,1', '... and leaves the receiver unchanged (V8: 5,4,3,2,1)' );

  $arr = [ 3, 1, 2 ];
  $L->js_array_sort( $arr, sub { push @$arr, 9 if @$arr < 6; $_[0] - $_[1] } );
  is( join( ',', @$arr ), '1,2,3,9,9,9', 'a comparator that grows the array keeps its tail (V8: 1,2,3,9,9,9)' );
  $arr = [ 3, 1, 2, 0 ];
  $L->js_array_sort( $arr, sub { pop @$arr if @$arr > 1; $_[0] - $_[1] } );
  is( join( ',', @$arr ), '0,1,2,3', 'one that shrinks it is written back to the old length (V8: 0,1,2,3)' );
  $arr = [ 3, undef, 1 ];
  $L->js_array_sort( $arr, sub { @$arr = (); $_[0] - $_[1] } );
  is_deeply( $arr, [ 1, 3, undef ], 'one that empties it too, undefined last (V8: [1,3,undefined])' );

  my @args;
  $L->js_array_sort( [ 2, 1 ], sub { push @args, scalar @_; -1 } );
  is_deeply( \@args, [2], 'the comparator gets (x, y) and nothing else' );

  my $calls = 0;
  for my $short ( [], [5], [undef], [ undef, 1 ], [ 1, undef, undef ] ) {
    $L->js_array_sort( $short, sub { $calls++; 0 } );
  }
  is( $calls, 0, 'fewer than two values that are not undefined: the comparator is never called' );
  my $one_def = [ undef, 'b', undef ];
  $L->js_array_sort($one_def);
  is_deeply( $one_def, [ 'b', undef, undef ], '... and the undefined still go last (V8: [b,undefined,undefined])' );

  my $same = [ 2, 1 ];
  ok( $L->js_array_sort($same) == $same, 'returns the receiver' );

  for my $c (
    [ 5,                                   '5' ],
    [ 'x',                                 'x' ],
    [ '',                                  '' ],
    [ $JS_NONE,                            'null' ],
    [ true,                                'true' ],
    [ 1.5,                                 '1.5' ],
    [ -0.0,                                '0' ],
    [ $SORT_INF,                           'Infinity' ],
    [ {},                                  '#<Object>' ],
    [ [ 1, 2 ],                            '[object Array]' ],
    [ 'Text::Nunjucks::Runtime'->make_regex( 'a', 'g' ),  '[object RegExp]' ],
    [ 'Text::Nunjucks::Runtime'->SafeString->new('ab'),   '[object Object]' ],
    # V8 NoSideEffectsToString on a plain object (oracle: [2, 1].sort(x)): an
    # own toString hides Object.prototype's -- '[object Object]' whatever it
    # holds; else an own constructor that is no named function does
    [ { a => 1 },                                          '#<Object>' ],
    [ { toString => 1 },                                   '[object Object]' ],
    [ { toString => undef },                               '[object Object]' ],
    [ { toString => 1, constructor => sub { } },           '[object Object]' ],
    [ { constructor => 1 },                                '[object Object]' ],
    [ { constructor => '' },                               '[object Object]' ],
    [ { constructor => undef },                            '[object Object]' ],
    [ { constructor => [] },                               '[object Object]' ],
    [ { constructor => 'x' },                              '[object Object]' ],
    [ { valueOf => 1 },                                    '#<Object>' ],
    [ Hash::Ordered->new( toString => 1 ),                 '[object Object]' ],
    [ Hash::Ordered->new( constructor => 1 ),              '[object Object]' ],
    [ Hash::Ordered->new( a => 1 ),                        '#<Object>' ],
    [ 'Text::Nunjucks::Runtime'->make_keyword_args( { toString => 1 } ),    '[object Object]' ],
    [ 'Text::Nunjucks::Runtime'->make_keyword_args( { constructor => 1 } ), '[object Object]' ],
    [ 'Text::Nunjucks::Runtime'->make_keyword_args( { a => 1 } ),           '#<Object>' ],
    # a coderef has no name yet (k88): V8's anonymous-function constructor
    # (node: {constructor: [function(){}][0]}) -- '[object Object]'
    [ { constructor => sub { } },                          '[object Object]' ],
  ) {
    my ( $cmpfn, $shown ) = @$c;
    for my $target ( [], [ 2, 1 ] ) {
      my $e = do { local $@; eval { $L->js_array_sort( $target, $cmpfn ); 1 } ? undef : $@ };
      ok( $e && $e->isa('Text::Nunjucks::Lib::Error') && $e->name eq 'TypeError'
          && $e->message eq 'The comparison function must be either a function or undefined: ' . $shown,
        'a comparefn neither undefined nor callable throws, before the length is looked at: ' . $shown );
    }
  }

  # A function constructor shows by its name (oracle: {'constructor': m} with a
  # macro m -> '#<macro>'; node: a named function foo -> '#<foo>'), which comes
  # from Runtime _js_function_name -- the one place k88 gives functions theirs.
  {
    no warnings 'redefine';
    local *Text::Nunjucks::Runtime::_js_function_name = sub { 'macro' };
    for my $cmpfn ( { constructor => sub { } }, Hash::Ordered->new( constructor => sub { } ) ) {
      my $e = do { local $@; eval { $L->js_array_sort( [ 2, 1 ], $cmpfn ); 1 } ? undef : $@ };
      is( $e && $e->message, 'The comparison function must be either a function or undefined: #<macro>',
        'an own constructor that is a named function: #<name> (' . ref($cmpfn) . ')' );
    }
    my $e = do { local $@; eval { $L->js_array_sort( [ 2, 1 ], { toString => 1, constructor => sub { } } ); 1 } ? undef : $@ };
    is( $e && $e->message, 'The comparison function must be either a function or undefined: [object Object]',
      '... unless an own toString hides Object.prototype.toString' );
  }
};

#### node built-ins -- path, fs.readFileSync's UTF-8 decode (k19, ADR 0018)

# t/data/node-builtins.json is written by maint/node-builtins-fixtures with the
# oracle's node (v24.19.0): path.resolve / normalize / dirname over generated
# paths, run with process.cwd() '/', and readFileSync(p, 'utf-8') over
# generated byte strings, as code points.
my $NODE_FIXTURES = do {
  my $file = Path::Tiny::path(__FILE__)->parent->child( 'data', 'node-builtins.json' );
  JSON::MaybeXS->new( utf8 => 1 )->decode( $file->slurp_raw );
};

subtest 'node path: resolve, normalize, dirname as node v24.19.0' => sub {
  my %fn = (
    resolve   => sub { $L->node_path_resolve(@_) },
    normalize => sub { $L->node_path_normalize(@_) },
    dirname   => sub { $L->node_path_dirname(@_) },
  );
  my $cwd = Cwd::getcwd();
  chdir '/' or die "chdir /: $!";
  my ( $n, @bad ) = (0);
  for my $c ( @{ $NODE_FIXTURES->{path} } ) {
    $n++;
    my $got = $fn{ $c->{fn} }->( @{ $c->{args} } );
    push @bad, $c->{fn} . '(' . join( ', ', map {"'$_'"} @{ $c->{args} } ) . ") = '$got', node '$c->{result}'"
      unless $got eq $c->{result};
  }
  chdir $cwd or die "chdir $cwd: $!";
  ok( $n > 1000, "$n fixture cases" );
  SKIP: {
    skip 'POSIX path model; path.win32 comes later', 1 if $^O eq 'MSWin32';
    is( scalar(@bad), 0, 'every case as node' ) or diag( join "\n", @bad[ 0 .. ( $#bad < 9 ? $#bad : 9 ) ] );
  }

  # resolve reads the working directory only where node does
  is( $L->node_path_resolve('views'), $cwd . '/views', "resolve('views') is anchored at the cwd" );
  is( $L->node_path_resolve('.'),     $cwd,            "resolve('.') is the cwd" );
};

# The pathArgs fixture's arguments: JSON values as the corpus harness reads
# them (null is the None sentinel, ADR 0006), and its {"$": kind} tags.
my $NODE_INF = 9**9**9;
sub node_fixture_arg {
  my ($v) = @_;
  return 'Text::Nunjucks::Runtime'->None unless defined $v;
  return ( $v ? true : false ) if JSON::MaybeXS::is_bool($v);
  return [ map { node_fixture_arg($_) } @$v ] if ref $v eq 'ARRAY';
  return $v unless ref $v eq 'HASH';
  return { map { $_ => node_fixture_arg( $v->{$_} ) } keys %$v } unless exists $v->{'$'};
  my $t = $v->{'$'};
  return $t eq 'undefined'   ? undef
    : $t eq '-0'             ? -0.0
    : $t eq 'NaN'            ? $NODE_INF - $NODE_INF
    : $t eq 'Infinity'       ? $NODE_INF
    : $t eq '-Infinity'      ? -$NODE_INF
    : $t eq 'function'       ? sub { }
    : $t eq 'SafeString'     ? 'Text::Nunjucks::Runtime'->SafeString->new( $v->{value} )
    : $t eq 'RegExp'         ? 'Text::Nunjucks::Runtime'->make_regex( $v->{source}, '' )
    : $t eq 'KeywordArgs'    ? 'Text::Nunjucks::Runtime'->make_keyword_args( node_fixture_arg( $v->{value} ) )
    :                          die "unknown fixture tag $t";
}

subtest "node path: validateString's TypeError for what is no string" => sub {
  my %fn = (
    resolve   => sub { $L->node_path_resolve(@_) },
    normalize => sub { $L->node_path_normalize(@_) },
    dirname   => sub { $L->node_path_dirname(@_) },
  );
  my $cwd = Cwd::getcwd();
  chdir '/' or die "chdir /: $!";
  my ( $n, $errors, @bad ) = ( 0, 0 );
  for my $c ( @{ $NODE_FIXTURES->{pathArgs} } ) {
    $n++;
    my $call = $c->{fn} . '(' . JSON::MaybeXS->new( canonical => 1 )->encode( $c->{args} ) . ')';
    my $got  = eval { $fn{ $c->{fn} }->( map { node_fixture_arg($_) } @{ $c->{args} } ) };
    my $err  = $@;
    if ( $c->{error} ) {
      $errors++;
      my $shown = ref($err) && $err->isa('Text::Nunjucks::Lib::Error') ? $err->name . ': ' . $err->message
        : $err ? 'died: ' . $err
        :        "returned '" . ( $got // 'undef' ) . "'";
      my $want = $c->{error}{name} . ': ' . $c->{error}{message};
      push @bad, "$call: $shown, node $want" unless $shown eq $want;
    }
    else {
      push @bad, "$call: " . ( $err ? 'died: ' . ( ref $err ? $err->message : $err ) : "'$got'" ) . ", node '$c->{result}'"
        unless !$err && $got eq $c->{result};
    }
  }
  chdir $cwd or die "chdir $cwd: $!";
  ok( $n > 150 && $errors > 100, "$n fixture cases, $errors of them throw" );
  is( scalar(@bad), 0, 'every case as node' ) or diag( join "\n", @bad[ 0 .. ( $#bad < 9 ? $#bad : 9 ) ] );
};

subtest "node fs.readFileSync(p, 'utf-8'): the WHATWG UTF-8 decode" => sub {
  my ( $n, @bad ) = (0);
  for my $c ( @{ $NODE_FIXTURES->{utf8} } ) {
    $n++;
    my $got = join ' ', map { ord } split //, $L->_node_utf8_decode( pack 'H*', $c->{hex} );
    my $want = join ' ', @{ $c->{codepoints} };
    push @bad, "$c->{hex}: [$got], node [$want]" unless $got eq $want;
  }
  ok( $n > 800, "$n fixture cases" );
  is( scalar(@bad), 0, 'every byte string decodes as node' ) or diag( join "\n", @bad[ 0 .. ( $#bad < 9 ? $#bad : 9 ) ] );
};

subtest 'node fs: existsSync and the readFileSync errors' => sub {
  my $dir  = Path::Tiny->tempdir;
  my $file = $dir->child('a.njk');
  $file->spew_raw("\xEF\xBB\xBFa\xC3\xA9");
  ok( $L->node_fs_exists_sync("$file"), 'existsSync: a file' );
  ok( $L->node_fs_exists_sync("$dir"),  'existsSync: a directory' );
  ok( !$L->node_fs_exists_sync( $dir->child('nope') ), 'existsSync: nothing there' );
  ok( !$L->node_fs_exists_sync("$file\0x"), 'existsSync: a NUL in the name is false, no error' );
  is( $L->node_fs_read_file_sync_utf8("$file"), "\x{FEFF}a\x{E9}", 'readFileSync keeps the BOM and decodes UTF-8' );

  # a name with non-ASCII characters is opened by its UTF-8 bytes, as node does
  my $name = "\x{E9}\x{1F600}.njk";
  my $raw  = $name;
  utf8::encode($raw);
  Path::Tiny::path( "$dir/" . $raw )->spew_raw('x');
  ok( $L->node_fs_exists_sync( "$dir/" . $name ), 'existsSync: a non-ASCII name' );
  is( $L->node_fs_read_file_sync_utf8( "$dir/" . $name ), 'x', 'readFileSync: a non-ASCII name' );

  my $e = do { local $@; eval { $L->node_fs_read_file_sync_utf8("$dir"); 1 } ? undef : $@ };
  ok( $e && $e->isa('Text::Nunjucks::Lib::Error'), 'a directory throws an Error' );
  is( $e && $e->name,    'Error',                                         '... named Error' );
  SKIP: {
    skip 'POSIX path model; path.win32 comes later (open on a directory is EACCES there)', 1 if $^O eq 'MSWin32';
    is( $e && $e->message, 'EISDIR: illegal operation on a directory, read', "... with node's message" );
  }

  # node: existsSync is false for a dangling symlink, and readFileSync fails
  # in its open, naming the path
  SKIP: {
    my $link = $dir->child('dangling');
    skip 'no symlinks here', 3 unless eval { symlink( 'nowhere', "$link" ) };
    ok( !$L->node_fs_exists_sync("$link"), 'existsSync: a dangling symlink is false' );
    $e = do { local $@; eval { $L->node_fs_read_file_sync_utf8("$link"); 1 } ? undef : $@ };
    ok( $e && $e->isa('Text::Nunjucks::Lib::Error'), 'readFileSync: a dangling symlink throws an Error' );
    is( $e && $e->message, "ENOENT: no such file or directory, open '$link'", "... with node's message, the path after open" );
  }

  # node takes no lock to read: a file another open file description holds
  # LOCK_EX on is read at once (Path::Tiny's slurp waits for LOCK_SH)
  SKIP: {
    skip 'POSIX path model; path.win32 comes later (Windows locks are mandatory)', 1 if $^O eq 'MSWin32';
    open( my $holder, '+<', "$file" ) or die "open: $!";
    skip 'no flock here', 1 unless flock( $holder, Fcntl::LOCK_EX() | Fcntl::LOCK_NB() );
    my $got = eval {
      local $SIG{ALRM} = sub { die "blocked\n" };
      alarm 5;
      my $s = $L->node_fs_read_file_sync_utf8("$file");
      alarm 0;
      $s;
    };
    alarm 0;
    is( $got // 'died: ' . $@, "\x{FEFF}a\x{E9}", 'readFileSync reads a file locked LOCK_EX elsewhere' );
    close $holder;
  }

  SKIP: {
    skip 'POSIX path model; path.win32 comes later (no chmod 0000 on Windows)', 2 if $^O eq 'MSWin32';
    skip 'running as root: every file is readable', 2 if $> == 0;
    chmod 0000, "$file" or die "chmod: $!";
    $e = do { local $@; eval { $L->node_fs_read_file_sync_utf8("$file"); 1 } ? undef : $@ };
    chmod 0644, "$file";
    ok( $e && $e->isa('Text::Nunjucks::Lib::Error'), 'an unreadable file throws an Error' );
    is( $e && $e->message, "EACCES: permission denied, open '$file'", "... with node's message, the path after open" );
  }
};

done_testing;
