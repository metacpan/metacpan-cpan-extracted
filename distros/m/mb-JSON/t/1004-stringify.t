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

# stringify is defined
push @tests, sub { ok(defined &mb::JSON::stringify, 'stringify: function exists') };

# stringify returns same result as encode
push @tests, sub {
    is( mb::JSON::stringify(undef), mb::JSON::encode(undef),
        'stringify eq encode: undef' );
};

# undef -> null
push @tests, sub { is( mb::JSON::stringify(undef), 'null', 'stringify: undef -> null' ) };

# boolean objects
push @tests, sub { is( mb::JSON::stringify(mb::JSON::true),  'true',  'stringify: true'  ) };
push @tests, sub { is( mb::JSON::stringify(mb::JSON::false), 'false', 'stringify: false' ) };

# plain 1 is a number, NOT true
push @tests, sub { is( mb::JSON::stringify(1), '1', 'stringify: 1 -> number 1 (not true)' ) };

# plain 0 is a number, NOT false
push @tests, sub { is( mb::JSON::stringify(0), '0', 'stringify: 0 -> number 0 (not false)' ) };

# numbers
push @tests, sub { is( mb::JSON::stringify(42),   '42',   'stringify: integer'  ) };
push @tests, sub { is( mb::JSON::stringify(-7),   '-7',   'stringify: negative' ) };
push @tests, sub { is( mb::JSON::stringify(3.14), '3.14', 'stringify: float'    ) };

# string
push @tests, sub { is( mb::JSON::stringify('hello'), '"hello"', 'stringify: string' ) };

# string escapes
push @tests, sub { is( mb::JSON::stringify("a\nb"), '"a\\nb"', 'stringify: newline escape' ) };
push @tests, sub { is( mb::JSON::stringify("a\tb"), '"a\\tb"', 'stringify: tab escape'     ) };
push @tests, sub { is( mb::JSON::stringify("a\rb"), '"a\\rb"', 'stringify: CR escape'      ) };
push @tests, sub { is( mb::JSON::stringify('a"b'),  '"a\\"b"', 'stringify: quote escape'   ) };
push @tests, sub { is( mb::JSON::stringify('a\\b'), '"a\\\\b"','stringify: backslash escape') };

# control character escape
push @tests, sub { is( mb::JSON::stringify("a\x01b"), '"a\\u0001b"', 'stringify: control char \\u0001' ) };

# UTF-8 kept as-is (not \uXXXX)
push @tests, sub {
    my $ja = chr(0xE7).chr(0x94).chr(0xB0).chr(0xE4).chr(0xB8).chr(0xAD); # U+7530 U+4E2D
    is( mb::JSON::stringify($ja), '"' . $ja . '"', 'stringify: UTF-8 bytes kept as-is' );
};
push @tests, sub {
    my $hi = chr(0xE3).chr(0x81).chr(0x82).chr(0xE3).chr(0x81).chr(0x84).chr(0xE3).chr(0x81).chr(0x86); # U+3042 U+3044 U+3046
    is( mb::JSON::stringify($hi), '"' . $hi . '"', 'stringify: UTF-8 hiragana kept as-is' );
};

# empty string
push @tests, sub { is( mb::JSON::stringify(''), '""', 'stringify: empty string' ) };

# empty array
push @tests, sub { is( mb::JSON::stringify([]), '[]', 'stringify: empty array' ) };

# empty hash
push @tests, sub { is( mb::JSON::stringify({}), '{}', 'stringify: empty hash' ) };

# array
push @tests, sub { is( mb::JSON::stringify([1,2,3]),   '[1,2,3]',   'stringify: integer array' ) };
push @tests, sub { is( mb::JSON::stringify(['a','b']), '["a","b"]', 'stringify: string array'  ) };

# array with mixed types
push @tests, sub {
    is( mb::JSON::stringify([1,'two',undef,mb::JSON::true]),
        '[1,"two",null,true]', 'stringify: mixed array' );
};

# hash - keys sorted alphabetically
push @tests, sub {
    is( mb::JSON::stringify({b=>2,a=>1}),
        '{"a":1,"b":2}', 'stringify: hash keys sorted' );
};
push @tests, sub {
    is( mb::JSON::stringify({name=>'Alice',age=>30}),
        '{"age":30,"name":"Alice"}', 'stringify: hash age/name sorted' );
};

# hash with undef value
push @tests, sub { is( mb::JSON::stringify({k=>undef}), '{"k":null}', 'stringify: hash undef -> null' ) };

# hash with boolean
push @tests, sub {
    is( mb::JSON::stringify({f=>mb::JSON::false,t=>mb::JSON::true}),
        '{"f":false,"t":true}', 'stringify: hash with booleans' );
};

# nested
push @tests, sub {
    is( mb::JSON::stringify({list=>[1,2,3]}),
        '{"list":[1,2,3]}', 'stringify: nested array in hash' );
};

# deeply nested
push @tests, sub {
    is( mb::JSON::stringify([[1,2],[3,4]]),
        '[[1,2],[3,4]]', 'stringify: nested arrays' );
};

# UTF-8 key
push @tests, sub {
    my $key = chr(0xE5).chr(0x90).chr(0x8D).chr(0xE5).chr(0x89).chr(0x8D); # U+540D U+524D
    is( mb::JSON::stringify({$key => 'test'}),
        '{"' . $key . '":"test"}', 'stringify: UTF-8 key in hash' );
};

# roundtrip parse -> stringify
push @tests, sub {
    my $orig = '{"active":true,"count":3,"name":"test","ok":false}';
    my $rt   = mb::JSON::stringify(mb::JSON::parse($orig));
    is($rt, $orig, 'roundtrip: parse then stringify');
};
push @tests, sub {
    my $arr_orig = '[1,"two",null,true,false]';
    my $arr_rt   = mb::JSON::stringify(mb::JSON::parse($arr_orig));
    is($arr_rt, $arr_orig, 'roundtrip: array parse then stringify');
};

# roundtrip stringify -> parse
push @tests, sub {
    my $data = { name => 'Bob', score => 99, active => mb::JSON::true };
    my $back = mb::JSON::parse(mb::JSON::stringify($data));
    is($back->{name}, 'Bob', 'roundtrip: stringify then parse name');
};
push @tests, sub {
    my $data = { name => 'Bob', score => 99, active => mb::JSON::true };
    my $back = mb::JSON::parse(mb::JSON::stringify($data));
    is($back->{score}, 99, 'roundtrip: stringify then parse score');
};
push @tests, sub {
    my $data = { name => 'Bob', score => 99, active => mb::JSON::true };
    my $back = mb::JSON::parse(mb::JSON::stringify($data));
    ok(ref($back->{active}) eq 'mb::JSON::Boolean' && $back->{active},
       'roundtrip: boolean preserved');
};

# stringify in array
push @tests, sub { is( mb::JSON::stringify([0, 1, -1]), '[0,1,-1]', 'stringify: zero in array' ) };

# string that looks like a number
push @tests, sub { is( mb::JSON::stringify('007'), '"007"', 'stringify: leading-zero string stays string' ) };

# stringify produces identical output to encode (spot check)
push @tests, sub {
    my $complex = { x => [1, 'two', undef, mb::JSON::false], y => mb::JSON::true };
    is( mb::JSON::stringify($complex), mb::JSON::encode($complex),
        'stringify identical to encode: complex structure' );
};

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
