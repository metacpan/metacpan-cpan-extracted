######################################################################
#
# 1004-stringify.t - mb::JSON::stringify tests
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use mb::JSON;

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub ok   {
    my ($ok,$n) = @_;
    $T_RUN++; $T_FAIL++ unless $ok;
    print +($ok?'':'not ') . "ok $T_RUN" . ($n?" - $n":'') . "\n"; $ok
}
sub is   {
    my ($got,$exp,$n) = @_;
    my $ok = defined $got && defined $exp && "$got" eq "$exp";
    ok($ok, $n) or print "# got:      '$got'\n# expected: '$exp'\n";
}
END { exit 1 if $T_PLAN && $T_FAIL }

plan_tests(40);

# ok 1: stringify is defined
ok(defined &mb::JSON::stringify, 'stringify: function exists');

# ok 2: stringify returns same result as encode
is( mb::JSON::stringify(undef), mb::JSON::encode(undef),
    'stringify eq encode: undef' );

# ok 3: undef -> null
is( mb::JSON::stringify(undef), 'null', 'stringify: undef -> null' );

# ok 4-5: boolean objects
is( mb::JSON::stringify(mb::JSON::true),  'true',  'stringify: true'  );
is( mb::JSON::stringify(mb::JSON::false), 'false', 'stringify: false' );

# ok 6: plain 1 is a number, NOT true
is( mb::JSON::stringify(1), '1', 'stringify: 1 -> number 1 (not true)' );

# ok 7: plain 0 is a number, NOT false
is( mb::JSON::stringify(0), '0', 'stringify: 0 -> number 0 (not false)' );

# ok 8-10: numbers
is( mb::JSON::stringify(42),    '42',    'stringify: integer'  );
is( mb::JSON::stringify(-7),    '-7',    'stringify: negative' );
is( mb::JSON::stringify(3.14),  '3.14',  'stringify: float'    );

# ok 11: string
is( mb::JSON::stringify('hello'), '"hello"', 'stringify: string' );

# ok 12-16: string escapes
is( mb::JSON::stringify("a\nb"),  '"a\\nb"', 'stringify: newline escape' );
is( mb::JSON::stringify("a\tb"),  '"a\\tb"', 'stringify: tab escape'     );
is( mb::JSON::stringify("a\rb"),  '"a\\rb"', 'stringify: CR escape'      );
is( mb::JSON::stringify('a"b'),   '"a\\"b"', 'stringify: quote escape'   );
is( mb::JSON::stringify('a\\b'),  '"a\\\\b"','stringify: backslash escape');

# ok 17: control character escape
is( mb::JSON::stringify("a\x01b"), '"a\\u0001b"', 'stringify: control char \\u0001' );

# ok 18-19: UTF-8 kept as-is (not \uXXXX)
my $ja = chr(0xE7).chr(0x94).chr(0xB0).chr(0xE4).chr(0xB8).chr(0xAD); # U+7530 U+4E2D
is( mb::JSON::stringify($ja), '"' . $ja . '"', 'stringify: UTF-8 bytes kept as-is' );

my $hi = chr(0xE3).chr(0x81).chr(0x82).chr(0xE3).chr(0x81).chr(0x84).chr(0xE3).chr(0x81).chr(0x86); # U+3042 U+3044 U+3046
is( mb::JSON::stringify($hi), '"' . $hi . '"', 'stringify: UTF-8 hiragana kept as-is' );

# ok 20: empty string
is( mb::JSON::stringify(''), '""', 'stringify: empty string' );

# ok 21: empty array
is( mb::JSON::stringify([]), '[]', 'stringify: empty array' );

# ok 22: empty hash
is( mb::JSON::stringify({}), '{}', 'stringify: empty hash' );

# ok 23-24: array
is( mb::JSON::stringify([1,2,3]),     '[1,2,3]',     'stringify: integer array'  );
is( mb::JSON::stringify(['a','b']),   '["a","b"]',   'stringify: string array'   );

# ok 25: array with mixed types
is( mb::JSON::stringify([1,'two',undef,mb::JSON::true]),
    '[1,"two",null,true]', 'stringify: mixed array' );

# ok 26-27: hash - keys sorted alphabetically
is( mb::JSON::stringify({b=>2,a=>1}),
    '{"a":1,"b":2}', 'stringify: hash keys sorted' );

is( mb::JSON::stringify({name=>'Alice',age=>30}),
    '{"age":30,"name":"Alice"}', 'stringify: hash age/name sorted' );

# ok 28: hash with undef value
is( mb::JSON::stringify({k=>undef}), '{"k":null}', 'stringify: hash undef -> null' );

# ok 29: hash with boolean
is( mb::JSON::stringify({f=>mb::JSON::false,t=>mb::JSON::true}),
    '{"f":false,"t":true}', 'stringify: hash with booleans' );

# ok 30: nested
is( mb::JSON::stringify({list=>[1,2,3]}),
    '{"list":[1,2,3]}', 'stringify: nested array in hash' );

# ok 31: deeply nested
is( mb::JSON::stringify([[1,2],[3,4]]),
    '[[1,2],[3,4]]', 'stringify: nested arrays' );

# ok 32: UTF-8 key
my $key = chr(0xE5).chr(0x90).chr(0x8D).chr(0xE5).chr(0x89).chr(0x8D); # U+540D U+524D
is( mb::JSON::stringify({$key => 'test'}),
    '{"' . $key . '":"test"}', 'stringify: UTF-8 key in hash' );

# ok 33-34: roundtrip parse -> stringify
my $orig = '{"active":true,"count":3,"name":"test","ok":false}';
my $rt   = mb::JSON::stringify(mb::JSON::parse($orig));
is($rt, $orig, 'roundtrip: parse then stringify');

my $arr_orig = '[1,"two",null,true,false]';
my $arr_rt   = mb::JSON::stringify(mb::JSON::parse($arr_orig));
is($arr_rt, $arr_orig, 'roundtrip: array parse then stringify');

# ok 35-36: roundtrip stringify -> parse
my $data = { name => 'Bob', score => 99, active => mb::JSON::true };
my $json = mb::JSON::stringify($data);
my $back = mb::JSON::parse($json);
is($back->{name},  'Bob', 'roundtrip: stringify then parse name');
is($back->{score}, 99,    'roundtrip: stringify then parse score');

# ok 37: roundtrip boolean
ok(ref($back->{active}) eq 'mb::JSON::Boolean' && $back->{active},
   'roundtrip: boolean preserved');

# ok 38: encode in array
is( mb::JSON::stringify([0, 1, -1]), '[0,1,-1]', 'stringify: zero in array' );

# ok 39: string that looks like a number
is( mb::JSON::stringify('007'), '"007"', 'stringify: leading-zero string stays string' );

# ok 40: stringify produces identical output to encode (spot check)
my $complex = { x => [1, 'two', undef, mb::JSON::false], y => mb::JSON::true };
is( mb::JSON::stringify($complex), mb::JSON::encode($complex),
    'stringify identical to encode: complex structure' );
