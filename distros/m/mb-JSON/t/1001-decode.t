######################################################################
#
# 1001-decode.t - mb::JSON::decode / parse tests
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
    ok($ok, $n) or print "# got: " . (defined $got ? "'$got'" : 'undef')
                       . "  expected: '$exp'\n";
}
sub is_undef {
    my ($got,$n) = @_;
    ok(!defined($got), $n) or print "# got: '$got' expected: undef\n";
}
END { exit 1 if $T_PLAN && $T_FAIL }

plan_tests(46);

# ok 1: parse is defined (alias for decode)
ok(defined &mb::JSON::parse, 'parse: function exists (alias for decode)');

# ok 2-3: string

is( mb::JSON::decode('"hello"'), 'hello', 'decode: simple string' );
is( mb::JSON::decode('"foo bar"'), 'foo bar', 'decode: string with space' );

# ok 4-6: numbers
is( mb::JSON::decode('42'),    42,    'decode: integer' );
is( mb::JSON::decode('3.14'),  3.14,  'decode: float' );
is( mb::JSON::decode('-7'),    -7,    'decode: negative' );

# ok 7-8: null
is_undef( mb::JSON::decode('null'), 'decode: null -> undef' );

# ok 9-10: true / false are Boolean objects
my $t = mb::JSON::decode('true');
my $f = mb::JSON::decode('false');
ok(ref($t) eq 'mb::JSON::Boolean', 'decode: true -> Boolean object');
ok(ref($f) eq 'mb::JSON::Boolean', 'decode: false -> Boolean object');

# ok 11-12: Boolean numifies
ok($t == 1, 'decode: true numifies to 1');
ok($f == 0, 'decode: false numifies to 0');

# ok 13-14: Boolean stringifies
is("$t", 'true',  'decode: true stringifies to "true"');
is("$f", 'false', 'decode: false stringifies to "false"');

# ok 15-16: Boolean booleans
ok($t == 1,  'decode: true is true in boolean context');
ok($f == 0, 'decode: false is false in boolean context');

# ok 17-19: array
my $a = mb::JSON::decode('[1,"two",3]');
ok(ref($a) eq 'ARRAY',    'decode: array ref');
is($a->[0], 1,     'decode: array [0]');
is($a->[1], 'two', 'decode: array [1]');

# ok 20-22: object / hash
my $h = mb::JSON::decode('{"name":"Alice","age":30}');
ok(ref($h) eq 'HASH',    'decode: hash ref');
is($h->{name}, 'Alice',  'decode: hash name');
is($h->{age},  30,       'decode: hash age');

# ok 23-24: nested
my $n = mb::JSON::decode('{"list":[1,2,3]}');
is($n->{list}[1], 2, 'decode: nested array in object');

my $n2 = mb::JSON::decode('[{"k":"v"}]');
is($n2->[0]{k}, 'v', 'decode: nested object in array');

# ok 25-26: escape sequences
is( mb::JSON::decode('"a\\nb"'),  "a\nb",  'decode: \\n escape' );
is( mb::JSON::decode('"a\\tb"'),  "a\tb",  'decode: \\t escape' );

# ok 27: 7: unicode escape
is( mb::JSON::decode('"\\u0041"'), 'A', 'decode: \\u0041 -> A' );

# ok 28-29: UTF-8 multibyte
# U+7530 U+4E2D in UTF-8 bytes
my $tanaka = chr(0xE7).chr(0x94).chr(0xB0).chr(0xE4).chr(0xB8).chr(0xAD);
my $mb = mb::JSON::decode('{"name":"' . $tanaka . '"}');
is( $mb->{name}, $tanaka, 'decode: UTF-8 bytes in string' );

# U+3042 U+3044 U+3046 in UTF-8 bytes
my $aiou = chr(0xE3).chr(0x81).chr(0x82).chr(0xE3).chr(0x81).chr(0x84).chr(0xE3).chr(0x81).chr(0x86);
my $mb2 = mb::JSON::decode('"' . $aiou . '"');
is( $mb2, $aiou, 'decode: UTF-8 hiragana string' );

# ok 30: 0: empty object
my $empty = mb::JSON::decode('{}');
ok(ref($empty) eq 'HASH' && !%$empty, 'decode: empty object');

# ok 31: 1: empty array
my $ea = mb::JSON::decode('[]');
ok(ref($ea) eq 'ARRAY' && !@$ea, 'decode: empty array');

# ok 32: 2: whitespace tolerance
my $ws = mb::JSON::decode(' { "k" : "v" } ');
is($ws->{k}, 'v', 'decode: whitespace tolerance');

# ok 33: 3: null in object
my $no = mb::JSON::decode('{"x":null}');
is_undef($no->{x}, 'decode: null value in object');

# ok 34: 4: parse() is alias for decode()
my $pa = mb::JSON::parse('{"k":"v"}');
is($pa->{k}, 'v', 'parse() is alias for decode()');

# ok 35: 5: $_ default
$_ = '"default"';
is( mb::JSON::decode(), 'default', 'decode: uses $_ when no arg' );
$_ = '"default"';
is( mb::JSON::parse(),  'default', 'parse: uses $_ when no arg' );

# ok 36: 7: boolean false in array
my $ba = mb::JSON::decode('[true,false,null]');
ok(ref($ba->[0]) eq 'mb::JSON::Boolean', 'decode: boolean in array [0]');
ok(ref($ba->[1]) eq 'mb::JSON::Boolean', 'decode: boolean in array [1]');

# ok 37: 9: integer zero
is( mb::JSON::decode('0'), 0, 'decode: integer zero' );

# ok 38-44: error handling
my $e;
eval { mb::JSON::decode('{bad}') }; $e = $@ ? 1 : 0;
ok($e, 'decode: bad object throws error');

eval { mb::JSON::decode('"unterminated') }; $e = $@ ? 1 : 0;
ok($e, 'decode: unterminated string throws error');

# each croak message
eval { mb::JSON::decode('{"a":1} garbage') }; $e=$@;
ok($e && $e=~/trailing garbage/, 'decode: trailing garbage error');

eval { mb::JSON::decode('') }; $e=$@;
ok($e && $e=~/unexpected (end|token)/, 'decode: empty input error');

eval { mb::JSON::decode('{42:1}') }; $e=$@;
ok($e && $e=~/expected string key/, 'decode: non-string key error');

eval { mb::JSON::decode('{"a" 1}') }; $e=$@;
ok($e && $e=~/expected ':'/, "decode: missing colon error");

eval { mb::JSON::decode('{"a":1 "b":2}') }; $e=$@;
ok($e && $e=~/expected ',' or '}'/, "decode: missing comma in object error");

eval { mb::JSON::decode('[1 2]') }; $e=$@;
ok($e && $e=~/expected ',' or ']'/, "decode: missing comma in array error");
