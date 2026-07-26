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

my ($T_RUN, $T_FAIL) = (0, 0);
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
# Assigning to $? sets the exit status; calling exit() from an END block
# aborts perl 5.6 and earlier with "Callback called exit."
END { $? = 1 if $T_FAIL }

my @tests;

# stringify is defined (alias for encode)
push @tests, sub { ok(defined &mb::JSON::stringify, 'stringify: function exists (alias for encode)') };

# undef -> null
push @tests, sub { is( mb::JSON::encode(undef), 'null', 'encode: undef -> null' ) };

# boolean objects
push @tests, sub { is( mb::JSON::encode(mb::JSON::true),  'true',  'encode: true'  ) };
push @tests, sub { is( mb::JSON::encode(mb::JSON::false), 'false', 'encode: false' ) };

# plain 1 is a number, NOT true
push @tests, sub { is( mb::JSON::encode(1), '1', 'encode: 1 -> number 1 (not true)' ) };

# plain 0 is a number, NOT false
push @tests, sub { is( mb::JSON::encode(0), '0', 'encode: 0 -> number 0 (not false)' ) };

# numbers
push @tests, sub { is( mb::JSON::encode(42),   '42',   'encode: integer'  ) };
push @tests, sub { is( mb::JSON::encode(-7),   '-7',   'encode: negative' ) };
push @tests, sub { is( mb::JSON::encode(3.14), '3.14', 'encode: float'    ) };

# string
push @tests, sub { is( mb::JSON::encode('hello'), '"hello"', 'encode: string' ) };

# string escapes
push @tests, sub { is( mb::JSON::encode("a\nb"), '"a\\nb"', 'encode: newline escape' ) };
push @tests, sub { is( mb::JSON::encode("a\tb"), '"a\\tb"', 'encode: tab escape'     ) };
push @tests, sub { is( mb::JSON::encode("a\rb"), '"a\\rb"', 'encode: CR escape'      ) };
push @tests, sub { is( mb::JSON::encode('a"b'),  '"a\\"b"', 'encode: quote escape'   ) };
push @tests, sub { is( mb::JSON::encode('a\\b'), '"a\\\\b"','encode: backslash escape') };

# control character escape
push @tests, sub { is( mb::JSON::encode("a\x01b"), '"a\\u0001b"', 'encode: control char \\u0001' ) };

# UTF-8 kept as-is (not \uXXXX)
push @tests, sub {
    my $ja = chr(0xE7).chr(0x94).chr(0xB0).chr(0xE4).chr(0xB8).chr(0xAD); # U+7530 U+4E2D
    is( mb::JSON::encode($ja), '"' . $ja . '"', 'encode: UTF-8 bytes kept as-is' );
};
push @tests, sub {
    my $hi = chr(0xE3).chr(0x81).chr(0x82).chr(0xE3).chr(0x81).chr(0x84).chr(0xE3).chr(0x81).chr(0x86); # U+3042 U+3044 U+3046
    is( mb::JSON::encode($hi), '"' . $hi . '"', 'encode: UTF-8 hiragana kept as-is' );
};

# empty string
push @tests, sub { is( mb::JSON::encode(''), '""', 'encode: empty string' ) };

# empty array
push @tests, sub { is( mb::JSON::encode([]), '[]', 'encode: empty array' ) };

# empty hash
push @tests, sub { is( mb::JSON::encode({}), '{}', 'encode: empty hash' ) };

# array
push @tests, sub { is( mb::JSON::encode([1,2,3]),   '[1,2,3]',   'encode: integer array' ) };
push @tests, sub { is( mb::JSON::encode(['a','b']), '["a","b"]', 'encode: string array'  ) };

# array with mixed types
push @tests, sub {
    is( mb::JSON::encode([1,'two',undef,mb::JSON::true]),
        '[1,"two",null,true]', 'encode: mixed array' );
};

# hash - keys sorted alphabetically
push @tests, sub {
    is( mb::JSON::encode({b=>2,a=>1}),
        '{"a":1,"b":2}', 'encode: hash keys sorted' );
};
push @tests, sub {
    is( mb::JSON::encode({name=>'Alice',age=>30}),
        '{"age":30,"name":"Alice"}', 'encode: hash age/name sorted' );
};

# hash with undef value
push @tests, sub { is( mb::JSON::encode({k=>undef}), '{"k":null}', 'encode: hash undef -> null' ) };

# hash with boolean
push @tests, sub {
    is( mb::JSON::encode({f=>mb::JSON::false,t=>mb::JSON::true}),
        '{"f":false,"t":true}', 'encode: hash with booleans' );
};

# nested
push @tests, sub {
    is( mb::JSON::encode({list=>[1,2,3]}),
        '{"list":[1,2,3]}', 'encode: nested array in hash' );
};

# deeply nested
push @tests, sub {
    is( mb::JSON::encode([[1,2],[3,4]]),
        '[[1,2],[3,4]]', 'encode: nested arrays' );
};

# UTF-8 key
push @tests, sub {
    my $key = chr(0xE5).chr(0x90).chr(0x8D).chr(0xE5).chr(0x89).chr(0x8D); # U+540D U+524D
    is( mb::JSON::encode({$key => 'test'}),
        '{"' . $key . '":"test"}', 'encode: UTF-8 key in hash' );
};

# roundtrip decode -> encode
push @tests, sub {
    my $orig = '{"active":true,"count":3,"name":"test","ok":false}';
    my $rt   = mb::JSON::encode(mb::JSON::decode($orig));
    is($rt, $orig, 'roundtrip: decode then encode');
};
push @tests, sub {
    my $arr_orig = '[1,"two",null,true,false]';
    my $arr_rt   = mb::JSON::encode(mb::JSON::decode($arr_orig));
    is($arr_rt, $arr_orig, 'roundtrip: array decode then encode');
};

# roundtrip encode -> decode
push @tests, sub {
    my $data = { name => 'Bob', score => 99, active => mb::JSON::true };
    my $back = mb::JSON::decode(mb::JSON::encode($data));
    is($back->{name}, 'Bob', 'roundtrip: encode then decode name');
};
push @tests, sub {
    my $data = { name => 'Bob', score => 99, active => mb::JSON::true };
    my $back = mb::JSON::decode(mb::JSON::encode($data));
    is($back->{score}, 99, 'roundtrip: encode then decode score');
};
push @tests, sub {
    my $data = { name => 'Bob', score => 99, active => mb::JSON::true };
    my $back = mb::JSON::decode(mb::JSON::encode($data));
    ok(ref($back->{active}) eq 'mb::JSON::Boolean' && $back->{active},
       'roundtrip: boolean preserved');
};

# encode integer zero in array
push @tests, sub { is( mb::JSON::encode([0, 1, -1]), '[0,1,-1]', 'encode: zero in array' ) };

# string that looks like a number
push @tests, sub { is( mb::JSON::encode('007'), '"007"', 'encode: leading-zero string stays string' ) };

# scientific notation
push @tests, sub { is( mb::JSON::encode(1e2), '100', 'encode: scientific notation -> number' ) };

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
