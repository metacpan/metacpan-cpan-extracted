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

my ($T_RUN, $T_FAIL) = (0, 0);
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
# Assigning to $? sets the exit status; calling exit() from an END block
# aborts perl 5.6 and earlier with "Callback called exit."
END { $? = 1 if $T_FAIL }

my @tests;

# parse is defined (alias for decode)
push @tests, sub { ok(defined &mb::JSON::parse, 'parse: function exists (alias for decode)') };

# string
push @tests, sub { is( mb::JSON::decode('"hello"'), 'hello', 'decode: simple string' ) };
push @tests, sub { is( mb::JSON::decode('"foo bar"'), 'foo bar', 'decode: string with space' ) };

# numbers
push @tests, sub { is( mb::JSON::decode('42'),   42,   'decode: integer'  ) };
push @tests, sub { is( mb::JSON::decode('3.14'), 3.14, 'decode: float'    ) };
push @tests, sub { is( mb::JSON::decode('-7'),   -7,   'decode: negative' ) };

# null
push @tests, sub { is_undef( mb::JSON::decode('null'), 'decode: null -> undef' ) };

# true / false are Boolean objects
push @tests, sub { my $t = mb::JSON::decode('true');  ok(ref($t) eq 'mb::JSON::Boolean', 'decode: true -> Boolean object')  };
push @tests, sub { my $f = mb::JSON::decode('false'); ok(ref($f) eq 'mb::JSON::Boolean', 'decode: false -> Boolean object') };

# Boolean numifies
push @tests, sub { my $t = mb::JSON::decode('true');  ok($t == 1, 'decode: true numifies to 1')  };
push @tests, sub { my $f = mb::JSON::decode('false'); ok($f == 0, 'decode: false numifies to 0') };

# Boolean stringifies
push @tests, sub { my $t = mb::JSON::decode('true');  is("$t", 'true',  'decode: true stringifies to "true"')   };
push @tests, sub { my $f = mb::JSON::decode('false'); is("$f", 'false', 'decode: false stringifies to "false"') };

# Boolean in boolean context
push @tests, sub { my $t = mb::JSON::decode('true');  ok($t == 1, 'decode: true is true in boolean context')  };
push @tests, sub { my $f = mb::JSON::decode('false'); ok($f == 0, 'decode: false is false in boolean context') };

# array
push @tests, sub { my $a = mb::JSON::decode('[1,"two",3]'); ok(ref($a) eq 'ARRAY', 'decode: array ref') };
push @tests, sub { my $a = mb::JSON::decode('[1,"two",3]'); is($a->[0], 1,     'decode: array [0]') };
push @tests, sub { my $a = mb::JSON::decode('[1,"two",3]'); is($a->[1], 'two', 'decode: array [1]') };

# object / hash
push @tests, sub { my $h = mb::JSON::decode('{"name":"Alice","age":30}'); ok(ref($h) eq 'HASH', 'decode: hash ref') };
push @tests, sub { my $h = mb::JSON::decode('{"name":"Alice","age":30}'); is($h->{name}, 'Alice', 'decode: hash name') };
push @tests, sub { my $h = mb::JSON::decode('{"name":"Alice","age":30}'); is($h->{age},  30,      'decode: hash age') };

# nested
push @tests, sub { my $n  = mb::JSON::decode('{"list":[1,2,3]}'); is($n->{list}[1], 2, 'decode: nested array in object') };
push @tests, sub { my $n2 = mb::JSON::decode('[{"k":"v"}]');      is($n2->[0]{k}, 'v', 'decode: nested object in array') };

# escape sequences
push @tests, sub { is( mb::JSON::decode('"a\\nb"'), "a\nb", 'decode: \\n escape' ) };
push @tests, sub { is( mb::JSON::decode('"a\\tb"'), "a\tb", 'decode: \\t escape' ) };

# unicode escape (BMP)
push @tests, sub { is( mb::JSON::decode('"\\u0041"'), 'A', 'decode: \\u0041 -> A' ) };

# surrogate pairs: \uXXXX\uXXXX -> single code point above U+FFFF (4-byte UTF-8)
# U+1F600 GRINNING FACE -> F0 9F 98 80
push @tests, sub {
    my $grin = chr(0xF0).chr(0x9F).chr(0x98).chr(0x80);
    is( mb::JSON::decode('"\\uD83D\\uDE00"'), $grin,
        'decode: surrogate pair \\uD83D\\uDE00 -> U+1F600 (4-byte UTF-8)' );
};
# U+1D11E MUSICAL SYMBOL G CLEF -> F0 9D 84 9E
push @tests, sub {
    my $clef = chr(0xF0).chr(0x9D).chr(0x84).chr(0x9E);
    is( mb::JSON::decode('"\\uD834\\uDD1E"'), $clef,
        'decode: surrogate pair \\uD834\\uDD1E -> U+1D11E (4-byte UTF-8)' );
};
push @tests, sub {
    my $se; eval { mb::JSON::decode('"\\uD83D"') }; $se = $@;
    ok( $se && $se =~ /lone high surrogate/, 'decode: lone high surrogate error' );
};
push @tests, sub {
    my $se; eval { mb::JSON::decode('"\\uDE00"') }; $se = $@;
    ok( $se && $se =~ /lone low surrogate/,  'decode: lone low surrogate error' );
};
push @tests, sub {
    my $se; eval { mb::JSON::decode('"\\uD83D\\u0041"') }; $se = $@;
    ok( $se && $se =~ /invalid low surrogate/, 'decode: high surrogate + non-low-surrogate error' );
};

# UTF-8 multibyte
# U+7530 U+4E2D in UTF-8 bytes
push @tests, sub {
    my $tanaka = chr(0xE7).chr(0x94).chr(0xB0).chr(0xE4).chr(0xB8).chr(0xAD);
    my $mb = mb::JSON::decode('{"name":"' . $tanaka . '"}');
    is( $mb->{name}, $tanaka, 'decode: UTF-8 bytes in string' );
};
# U+3042 U+3044 U+3046 in UTF-8 bytes
push @tests, sub {
    my $aiou = chr(0xE3).chr(0x81).chr(0x82).chr(0xE3).chr(0x81).chr(0x84).chr(0xE3).chr(0x81).chr(0x86);
    my $mb2 = mb::JSON::decode('"' . $aiou . '"');
    is( $mb2, $aiou, 'decode: UTF-8 hiragana string' );
};

# empty object / array
push @tests, sub { my $empty = mb::JSON::decode('{}'); ok(ref($empty) eq 'HASH'  && !%$empty, 'decode: empty object') };
push @tests, sub { my $ea    = mb::JSON::decode('[]'); ok(ref($ea)    eq 'ARRAY' && !@$ea,   'decode: empty array')  };

# whitespace tolerance
push @tests, sub { my $ws = mb::JSON::decode(' { "k" : "v" } '); is($ws->{k}, 'v', 'decode: whitespace tolerance') };

# null in object
push @tests, sub { my $no = mb::JSON::decode('{"x":null}'); is_undef($no->{x}, 'decode: null value in object') };

# parse() is alias for decode()
push @tests, sub { my $pa = mb::JSON::parse('{"k":"v"}'); is($pa->{k}, 'v', 'parse() is alias for decode()') };

# $_ default
push @tests, sub { local $_ = '"default"'; is( mb::JSON::decode(), 'default', 'decode: uses $_ when no arg' ) };
push @tests, sub { local $_ = '"default"'; is( mb::JSON::parse(),  'default', 'parse: uses $_ when no arg' ) };

# boolean in array
push @tests, sub { my $ba = mb::JSON::decode('[true,false,null]'); ok(ref($ba->[0]) eq 'mb::JSON::Boolean', 'decode: boolean in array [0]') };
push @tests, sub { my $ba = mb::JSON::decode('[true,false,null]'); ok(ref($ba->[1]) eq 'mb::JSON::Boolean', 'decode: boolean in array [1]') };

# integer zero
push @tests, sub { is( mb::JSON::decode('0'), 0, 'decode: integer zero' ) };

# error handling
push @tests, sub { my $e; eval { mb::JSON::decode('{bad}') }; $e = $@ ? 1 : 0; ok($e, 'decode: bad object throws error') };
push @tests, sub { my $e; eval { mb::JSON::decode('"unterminated') }; $e = $@ ? 1 : 0; ok($e, 'decode: unterminated string throws error') };
push @tests, sub { my $e; eval { mb::JSON::decode('{"a":1} garbage') }; $e = $@; ok($e && $e =~ /trailing garbage/, 'decode: trailing garbage error') };
push @tests, sub { my $e; eval { mb::JSON::decode('') }; $e = $@; ok($e && $e =~ /unexpected (end|token)/, 'decode: empty input error') };
push @tests, sub { my $e; eval { mb::JSON::decode('{42:1}') }; $e = $@; ok($e && $e =~ /expected string key/, 'decode: non-string key error') };
push @tests, sub { my $e; eval { mb::JSON::decode('{"a" 1}') }; $e = $@; ok($e && $e =~ /expected ':'/, "decode: missing colon error") };
push @tests, sub { my $e; eval { mb::JSON::decode('{"a":1 "b":2}') }; $e = $@; ok($e && $e =~ /expected ',' or '}'/, "decode: missing comma in object error") };
push @tests, sub { my $e; eval { mb::JSON::decode('[1 2]') }; $e = $@; ok($e && $e =~ /expected ',' or ']'/, "decode: missing comma in array error") };

# unrecognized backslash escape is rejected (strict)
push @tests, sub { my $e; eval { mb::JSON::decode('"a\\qb"') }; $e = $@; ok($e && $e =~ /invalid escape sequence/, 'decode: invalid escape sequence error') };

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
