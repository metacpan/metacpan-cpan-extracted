######################################################################
#
# 1002-encode.t - mb::JSON::encode tests
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

plan_tests(38);

# ok 1: undef -> null
is( mb::JSON::encode(undef), 'null', 'encode: undef -> null' );

# ok 2-3: boolean objects
is( mb::JSON::encode(mb::JSON::true),  'true',  'encode: true'  );
is( mb::JSON::encode(mb::JSON::false), 'false', 'encode: false' );

# ok 4: plain 1 is a number, NOT true
is( mb::JSON::encode(1), '1', 'encode: 1 -> number 1 (not true)' );

# ok 5: plain 0 is a number, NOT false
is( mb::JSON::encode(0), '0', 'encode: 0 -> number 0 (not false)' );

# ok 6-8: numbers
is( mb::JSON::encode(42),    '42',    'encode: integer'  );
is( mb::JSON::encode(-7),    '-7',    'encode: negative' );
is( mb::JSON::encode(3.14),  '3.14',  'encode: float'    );

# ok 9: string
is( mb::JSON::encode('hello'), '"hello"', 'encode: string' );

# ok 10-14: string escapes
is( mb::JSON::encode("a\nb"),  '"a\\nb"', 'encode: newline escape' );
is( mb::JSON::encode("a\tb"),  '"a\\tb"', 'encode: tab escape'     );
is( mb::JSON::encode("a\rb"),  '"a\\rb"', 'encode: CR escape'      );
is( mb::JSON::encode('a"b'),   '"a\\"b"', 'encode: quote escape'   );
is( mb::JSON::encode('a\\b'),  '"a\\\\b"','encode: backslash escape');

# ok 15: control character escape
is( mb::JSON::encode("a\x01b"), '"a\\u0001b"', 'encode: control char \\u0001' );

# ok 16-17: UTF-8 kept as-is (not \uXXXX)
my $ja = chr(0xE7).chr(0x94).chr(0xB0).chr(0xE4).chr(0xB8).chr(0xAD); # U+7530 U+4E2D
is( mb::JSON::encode($ja), '"' . $ja . '"', 'encode: UTF-8 bytes kept as-is' );

my $hi = chr(0xE3).chr(0x81).chr(0x82).chr(0xE3).chr(0x81).chr(0x84).chr(0xE3).chr(0x81).chr(0x86); # U+3042 U+3044 U+3046
is( mb::JSON::encode($hi), '"' . $hi . '"', 'encode: UTF-8 hiragana kept as-is' );

# ok 18: empty string
is( mb::JSON::encode(''), '""', 'encode: empty string' );

# ok 19: empty array
is( mb::JSON::encode([]), '[]', 'encode: empty array' );

# ok 20: empty hash
is( mb::JSON::encode({}), '{}', 'encode: empty hash' );

# ok 21-22: array
is( mb::JSON::encode([1,2,3]),     '[1,2,3]',     'encode: integer array'  );
is( mb::JSON::encode(['a','b']),   '["a","b"]',   'encode: string array'   );

# ok 23: array with mixed types
is( mb::JSON::encode([1,'two',undef,mb::JSON::true]),
    '[1,"two",null,true]', 'encode: mixed array' );

# ok 24-25: hash - keys sorted alphabetically
is( mb::JSON::encode({b=>2,a=>1}),
    '{"a":1,"b":2}', 'encode: hash keys sorted' );

is( mb::JSON::encode({name=>'Alice',age=>30}),
    '{"age":30,"name":"Alice"}', 'encode: hash age/name sorted' );

# ok 26: hash with undef value
is( mb::JSON::encode({k=>undef}), '{"k":null}', 'encode: hash undef -> null' );

# ok 27: hash with boolean
is( mb::JSON::encode({f=>mb::JSON::false,t=>mb::JSON::true}),
    '{"f":false,"t":true}', 'encode: hash with booleans' );

# ok 28: nested
is( mb::JSON::encode({list=>[1,2,3]}),
    '{"list":[1,2,3]}', 'encode: nested array in hash' );

# ok 29: deeply nested
is( mb::JSON::encode([[1,2],[3,4]]),
    '[[1,2],[3,4]]', 'encode: nested arrays' );

# ok 30: UTF-8 key
my $key = chr(0xE5).chr(0x90).chr(0x8D).chr(0xE5).chr(0x89).chr(0x8D); # U+540D U+524D
is( mb::JSON::encode({$key => 'test'}),
    '{"' . $key . '":"test"}', 'encode: UTF-8 key in hash' );

# ok 31-32: roundtrip decode -> encode
my $orig = '{"active":true,"count":3,"name":"test","ok":false}';
my $rt   = mb::JSON::encode(mb::JSON::decode($orig));
is($rt, $orig, 'roundtrip: decode then encode');

my $arr_orig = '[1,"two",null,true,false]';
my $arr_rt   = mb::JSON::encode(mb::JSON::decode($arr_orig));
is($arr_rt, $arr_orig, 'roundtrip: array decode then encode');

# ok 33-34: roundtrip encode -> decode
my $data = { name => 'Bob', score => 99, active => mb::JSON::true };
my $json = mb::JSON::encode($data);
my $back = mb::JSON::decode($json);
is($back->{name},  'Bob', 'roundtrip: encode then decode name');
is($back->{score}, 99,    'roundtrip: encode then decode score');

# ok 35: roundtrip boolean
ok(ref($back->{active}) eq 'mb::JSON::Boolean' && $back->{active},
   'roundtrip: boolean preserved');

# ok 36: encode integer zero in array
is( mb::JSON::encode([0, 1, -1]), '[0,1,-1]', 'encode: zero in array' );

# ok 37: string that looks like a number
is( mb::JSON::encode('007'), '"007"', 'encode: leading-zero string stays string' );

# ok 38: scientific notation
is( mb::JSON::encode(1e2), '100', 'encode: scientific notation -> number' );
