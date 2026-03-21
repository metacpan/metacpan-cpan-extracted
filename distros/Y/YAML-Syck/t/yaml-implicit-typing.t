use strict;
use warnings;

use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use Test::More;
use YAML::Syck qw(Dump Load);

# Comprehensive tests for YAML::Syck implicit type resolution.
# When $YAML::Syck::ImplicitTyping is enabled, the C-level resolver
# (implicit.c) classifies plain scalars into null, bool, int, float,
# and string types.

$YAML::Syck::ImplicitTyping = 1;

# Helper: load a plain scalar and return the Perl value
sub load_val {
    my ($scalar) = @_;
    my $data = Load("---\nv: $scalar\n");
    return $data->{v};
}

# ── Null types ──────────────────────────────────────────────────────
subtest 'null values' => sub {
    is( load_val('~'),    undef, '~ is null' );
    is( load_val('null'), undef, 'null is null' );
    is( load_val('Null'), undef, 'Null is null' );
    is( load_val('NULL'), undef, 'NULL is null' );
    is( Load("---\n"),    undef, 'empty document is null' );
};

# ── Boolean types ───────────────────────────────────────────────────
subtest 'boolean true values' => sub {
    for my $val (qw(y Y yes Yes YES true True TRUE on On ON)) {
        ok( load_val($val), "$val is truthy" );
    }
};

subtest 'boolean false values' => sub {
    for my $val (qw(n N no No NO false False FALSE off Off OFF)) {
        ok( !load_val($val), "$val is falsy" );
        is( load_val($val), '', "$val is empty string (false)" );
    }
};

# ── Integer types ───────────────────────────────────────────────────
subtest 'decimal integers' => sub {
    is( load_val('0'),     0,      'number 0' );
    is( load_val('1'),     1,      'number 1' );
    is( load_val('42'),    42,     'number 42' );
    is( load_val('-1'),    -1,     '-1' );
    is( load_val('+1'),    1,      '+1' );
    is( load_val('1000'),  1000,   'number 1000' );
};

subtest 'integers with commas (YAML 1.0)' => sub {
    is( load_val('1,000'),     1000,     '1,000' );
    is( load_val('1,000,000'), 1000000,  '1,000,000' );
};

subtest 'hexadecimal integers' => sub {
    is( load_val('0x0'),    0,   '0x0' );
    is( load_val('0x1A'),   26,  '0x1A' );
    is( load_val('0xff'),   255, '0xff' );
    is( load_val('0xDEAD'), 0xDEAD, '0xDEAD' );
};

subtest 'octal integers' => sub {
    is( load_val('00'),   0,   '00 (octal)' );
    is( load_val('01'),   1,   '01 (octal)' );
    is( load_val('010'),  8,   '010 (octal)' );
    is( load_val('0777'), 511, '0777 (octal)' );
};

subtest 'base60 (sexagesimal) integers' => sub {
    is( load_val('1:0'),    60,   '1:0 = 60' );
    is( load_val('1:30'),   90,   '1:30 = 90' );
    is( load_val('1:0:0'),  3600, '1:0:0 = 3600' );
};

# ── Float types ─────────────────────────────────────────────────────
subtest 'decimal floats' => sub {
    is( load_val('0.0'),   0,    '0.0' );
    is( load_val('1.5'),   1.5,  '1.5' );
    is( load_val('-3.14'), -3.14, '-3.14' );
    is( load_val('+2.5'),  2.5,  '+2.5' );
    # Scientific notation (YAML 1.0 requires explicit sign after exponent)
    is( load_val('1.0e+3'), 1000,   '1.0e+3' );
    is( load_val('1.0e-2'), 0.01,   '1.0e-2' );
    is( load_val('1.0E+3'), 1000,   '1.0E+3' );
    # Without explicit +/- sign, these are strings in YAML 1.0
    is( load_val('1.0e3'),  '1.0e3', '1.0e3 is string (no explicit sign)' );
    is( load_val('1.0E3'),  '1.0E3', '1.0E3 is string (no explicit sign)' );
};

subtest 'special float values' => sub {
    # Infinity
    ok( load_val('.inf')  == 9**9**9,  '.inf is infinity' );
    ok( load_val('.Inf')  == 9**9**9,  '.Inf is infinity' );
    ok( load_val('.INF')  == 9**9**9,  '.INF is infinity' );
    ok( load_val('+.inf') == 9**9**9,  '+.inf is infinity' );
    ok( load_val('-.inf') == -(9**9**9), '-.inf is negative infinity' );
    ok( load_val('-.Inf') == -(9**9**9), '-.Inf is negative infinity' );
    ok( load_val('-.INF') == -(9**9**9), '-.INF is negative infinity' );

    # NaN
    my $nan = load_val('.nan');
    ok( $nan != $nan, '.nan is NaN' );
    $nan = load_val('.NaN');
    ok( $nan != $nan, '.NaN is NaN' );
    $nan = load_val('.NAN');
    ok( $nan != $nan, '.NAN is NaN' );
};

subtest 'base60 (sexagesimal) floats' => sub {
    is( load_val('1:30.5'), 90.5, '1:30.5 = 90.5' );
};

# ── Strings (not converted) ────────────────────────────────────────
subtest 'values that remain strings' => sub {
    # These should NOT be converted to typed values
    is( load_val('hello'),  'hello',  'plain word is string' );
    is( load_val('0o17'),   '0o17',   '0o17 (Python octal) is string' );
    is( load_val('0b1010'), '0b1010', '0b1010 (binary) is string' );
    is( load_val('1_000'),  '1_000',  '1_000 (underscore num) is string' );
    is( load_val('08'),     '08',     '08 (invalid octal) is string' );
    is( load_val('09'),     '09',     '09 (invalid octal) is string' );
    is( load_val('0x'),     '0x',     '0x without digits is string' );
    is( load_val('0xGG'),   '0xGG',   '0xGG (invalid hex) is string' );
    is( load_val('+'),      '+',      'bare + is string' );
    is( load_val('.'),      '.',      'bare . is string' );
    is( load_val('..'),     '..',     '.. is string' );
    is( load_val('.0'),     '.0',     '.0 is string' );
};

# ── Quoted values bypass implicit typing ────────────────────────────
subtest 'quoted values are always strings' => sub {
    is( load_val("'true'"),  'true',  "single-quoted true is string" );
    is( load_val("'null'"),  'null',  "single-quoted null is string" );
    is( load_val("'42'"),    '42',    "single-quoted 42 is string" );
    is( load_val('"true"'),  'true',  "double-quoted true is string" );
    is( load_val('"null"'),  'null',  "double-quoted null is string" );
    is( load_val('"42"'),    '42',    "double-quoted 42 is string" );
    is( load_val("'~'"),     '~',     "single-quoted ~ is string" );
    is( load_val("'.inf'"),  '.inf',  "single-quoted .inf is string" );
    is( load_val("'0x1A'"),  '0x1A',  "single-quoted 0x1A is string" );
};

# ── ImplicitTyping off: everything is a string ──────────────────────
subtest 'ImplicitTyping disabled preserves strings' => sub {
    local $YAML::Syck::ImplicitTyping = 0;

    is( load_val('true'),  'true',  'true is string without ImplicitTyping' );
    is( load_val('false'), 'false', 'false is string without ImplicitTyping' );
    is( load_val('42'),    '42',    '42 is string without ImplicitTyping' );
    is( load_val('0x1A'),  '0x1A',  '0x1A is string without ImplicitTyping' );
    is( load_val('.inf'),  '.inf',  '.inf is string without ImplicitTyping' );
    is( load_val('1:30'),  '1:30',  '1:30 is string without ImplicitTyping' );
};

# ── Roundtrip: string values that look like types ───────────────────
# When Perl strings happen to look like YAML types, Dump must quote them
# so that Load returns the original string, not a typed value.
subtest 'string roundtrip with ImplicitTyping' => sub {
    my @keywords = qw(
        true false yes no on off null
        TRUE FALSE YES NO ON OFF NULL
        True False Yes No Null
    );
    for my $kw (@keywords) {
        is( Load(Dump($kw)), $kw, "roundtrip string '$kw'" );
    }
};

subtest 'numeric string roundtrip with ImplicitTyping' => sub {
    my @nums = ('0x10', '0x1A', '.inf', '-.inf', '+.inf', '.nan',
                '1:30', '1:30:00', '+1', '+42', '010');
    for my $n (@nums) {
        is( Load(Dump($n)), $n, "roundtrip string '$n'" );
    }
};

done_testing;
