use strict;
use warnings;
use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use Test::More;
use JSON::Syck;

# Test that JSON::Syck correctly handles JSON escape sequences.
# This covers issue #21 and issue #30.

my @load_tests = (
    # [ description, json_input, expected_bytes ]
    [ 'escaped double quote',    '"\\"hello\\""',  '"hello"' ],
    [ 'escaped backslash',       '"\\\\"',         '\\' ],
    [ 'escaped solidus',         '"\\/"',          '/' ],
    [ 'escaped backspace',       '"\\b"',          "\b" ],
    [ 'escaped form feed',       '"\\f"',          "\f" ],
    [ 'escaped newline',         '"\\n"',          "\n" ],
    [ 'escaped carriage return', '"\\r"',          "\r" ],
    [ 'escaped tab',             '"\\t"',          "\t" ],

    # \uXXXX unicode escapes
    [ 'unicode null \\u0000',    '"\\u0000"',      "\x00" ],
    [ 'unicode SOH \\u0001',     '"\\u0001"',      "\x01" ],
    [ 'unicode space \\u0020',   '"\\u0020"',      " " ],
    [ 'unicode A \\u0041',       '"\\u0041"',      "A" ],
    [ 'unicode tilde \\u007e',   '"\\u007e"',      "~" ],

    # Multi-byte UTF-8 from \uXXXX
    [ 'unicode e-acute \\u00e9', '"\\u00e9"',      "\xc3\xa9" ],       # UTF-8 for U+00E9
    [ 'unicode CJK \\u4e16',    '"\\u4e16"',      "\xe4\xb8\x96" ],   # UTF-8 for U+4E16 (世)

    # Mixed content
    [ 'solidus in URL',         '"http:\\/\\/example.com\\/"',  'http://example.com/' ],
    [ 'mixed escapes',          '"tab\\there\\nnewline"',       "tab\there\nnewline" ],
    [ 'unicode in text',        '"caf\\u00e9"',                 "caf\xc3\xa9" ],

    # Case-insensitive hex in \u
    [ 'uppercase hex \\u00E9',  '"\\u00E9"',      "\xc3\xa9" ],
    [ 'mixed case \\u00eF',    '"\\u00eF"',      "\xc3\xaf" ],

    # UTF-16 surrogate pairs (\uD800-\uDBFF + \uDC00-\uDFFF)
    [ 'surrogate pair U+1F600', '"\\uD83D\\uDE00"',  "\xF0\x9F\x98\x80" ],  # 😀
    [ 'surrogate pair U+1F4A9', '"\\uD83D\\uDCA9"',  "\xF0\x9F\x92\xA9" ],  # 💩
    [ 'surrogate pair U+10000', '"\\uD800\\uDC00"',   "\xF0\x90\x80\x80" ],  # first supplementary char

);

# Dump tests: verify JSON::Syck::Dump produces only valid JSON escape sequences
# JSON allows: \" \\ \/ \b \f \n \r \t \uXXXX — nothing else (no \xHH, \0, \a, \v, \e)
my @dump_tests = (
    # [ description, perl_value, expected_json ]
    [ 'dump tab',              "hello\tworld",    '"hello\tworld"' ],
    [ 'dump newline',          "hello\nworld",    '"hello\nworld"' ],
    [ 'dump carriage return',  "hello\rworld",    '"hello\rworld"' ],
    [ 'dump backspace',        "hello\bworld",    '"hello\bworld"' ],
    [ 'dump form feed',        "hello\fworld",    '"hello\fworld"' ],
    [ 'dump backslash',        'hello\\world',    '"hello\\\\world"' ],
    [ 'dump double quote',     'hello"world',     '"hello\\"world"' ],
    [ 'dump null byte',        "hello\x00world",  '"hello\u0000world"' ],
    [ 'dump SOH',              "hello\x01world",  '"hello\u0001world"' ],
    [ 'dump control char 0x1f', "hello\x1fworld", '"hello\u001fworld"' ],
    [ 'dump bell',             "hello\x07world",  '"hello\u0007world"' ],
    [ 'dump vertical tab',    "hello\x0bworld",   '"hello\u000bworld"' ],
    [ 'dump escape char',     "hello\x1bworld",   '"hello\u001bworld"' ],
    [ 'dump solidus',          'hello/world',      '"hello\/world"' ],
);

# Roundtrip tests: Load(Dump(x)) == x
my @roundtrip_tests = (
    [ 'roundtrip tab',         "line1\tline2" ],
    [ 'roundtrip newline',     "line1\nline2" ],
    [ 'roundtrip backspace',   "line1\bline2" ],
    [ 'roundtrip form feed',   "line1\fline2" ],
    [ 'roundtrip CR',          "line1\rline2" ],
    [ 'roundtrip null byte',   "line1\x00line2" ],
    [ 'roundtrip mixed',       "tab\there\nnew\r\n" ],
    [ 'roundtrip control chars', "\x01\x02\x1f" ],
    [ 'roundtrip solidus',     'http://example.com/' ],
);

plan tests => scalar(@load_tests) + scalar(@dump_tests) + scalar(@roundtrip_tests);

for my $test (@load_tests) {
    my ($desc, $input, $expected) = @$test;
    my $got = JSON::Syck::Load($input);
    is $got, $expected, "Load: $desc";
}

for my $test (@dump_tests) {
    my ($desc, $value, $expected) = @$test;
    my $got = JSON::Syck::Dump($value);
    is $got, $expected, "Dump: $desc";
}

for my $test (@roundtrip_tests) {
    my ($desc, $value) = @$test;
    my $got = JSON::Syck::Load(JSON::Syck::Dump($value));
    is $got, $value, "Roundtrip: $desc";
}
