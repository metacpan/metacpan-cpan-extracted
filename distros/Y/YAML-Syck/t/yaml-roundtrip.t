#!/usr/bin/perl
# yaml-roundtrip.t
#
# Consolidated round-trip tests for YAML 1.0 spec features.
# Each section covers a feature area that previously lacked Dump→Load→verify coverage.
#
# Pattern: is( Load(Dump($val)), $val ) or is_deeply( Load(Dump($struct)), $struct )

use strict;
use warnings;
use utf8;

use Test::More;
use YAML::Syck qw(Dump Load);

# ===== Block scalars =====
# Existing tests cover basic multiline and no-trailing-newline.
# Add: multiple trailing newlines, blank-line-separated paragraphs,
# single-char lines, and indented content.

{
    my $multi_trailing = "line one\nline two\n\n\n";
    is( Load(Dump({ c => $multi_trailing }))->{c}, $multi_trailing,
        'block scalar: multiple trailing newlines survive roundtrip' );
}

{
    my $paragraphs = "paragraph one\n\nparagraph two\n";
    is( Load(Dump({ c => $paragraphs }))->{c}, $paragraphs,
        'block scalar: blank-line-separated paragraphs roundtrip' );
}

{
    my $indented = "  indented line one\n  indented line two\n";
    is( Load(Dump({ c => $indented }))->{c}, $indented,
        'block scalar: leading-space content roundtrips' );
}

{
    my $single_chars = "a\nb\nc\n";
    is( Load(Dump($single_chars)), $single_chars,
        'block scalar: single-char lines roundtrip' );
}

{
    my $empty_lines_only = "\n\n\n";
    is( Load(Dump($empty_lines_only)), $empty_lines_only,
        'block scalar: only newlines roundtrip' );
}

# ===== Timestamps (ImplicitTyping) =====
# Existing test covers date without ImplicitTyping.
# Add: date, spaced, and ISO 8601 formats WITH ImplicitTyping.

{
    local $YAML::Syck::ImplicitTyping = 1;

    my $date = "2006-01-01";
    is( Load(Dump($date)), $date,
        'timestamp: date roundtrips with ImplicitTyping' );

    my $spaced = "2006-01-01 15:30:00";
    is( Load(Dump($spaced)), $spaced,
        'timestamp: spaced format roundtrips with ImplicitTyping' );

    my $iso_z = "2006-01-01T15:30:00Z";
    is( Load(Dump($iso_z)), $iso_z,
        'timestamp: ISO 8601 with Z roundtrips' );

    my $iso_tz = "2006-01-01T15:30:00+05:30";
    is( Load(Dump($iso_tz)), $iso_tz,
        'timestamp: ISO 8601 with timezone offset roundtrips' );
}

# ===== UTF-8 / Unicode =====
# Existing tests only verify Dump output format, no round-trips.

{
    local $YAML::Syck::ImplicitUnicode = 1;

    my $wide = "café ♥ naïve";
    is( Load(Dump($wide)), $wide,
        'utf8: wide characters roundtrip' );

    my $mixed = "ASCII and ünïcödé mixed";
    is( Load(Dump($mixed)), $mixed,
        'utf8: mixed ASCII and unicode roundtrip' );

    my $cjk = "\x{4e16}\x{754c}";    # 世界
    is( Load(Dump($cjk)), $cjk,
        'utf8: CJK characters roundtrip' );

    my $emoji = "test \x{1F600} emoji";
    is( Load(Dump($emoji)), $emoji,
        'utf8: emoji roundtrip' );

    my $struct = { name => "José", city => "Zürich" };
    is_deeply( Load(Dump($struct)), $struct,
        'utf8: unicode in hash values roundtrip' );
}

# ===== Flow collections =====
# Existing tests only parse pre-written YAML, no dump→load.

{
    my $nested_arrays = [[1, 2], [3, 4]];
    is_deeply( Load(Dump($nested_arrays)), $nested_arrays,
        'flow: nested arrays roundtrip' );

    my $nested_hashes = { outer => { inner => "value" } };
    is_deeply( Load(Dump($nested_hashes)), $nested_hashes,
        'flow: nested hashes roundtrip' );

    my $mixed = { list => [1, 2, 3], map => { a => "b" } };
    is_deeply( Load(Dump($mixed)), $mixed,
        'flow: mixed nested collections roundtrip' );

    my $deep = [[[["deep"]]]];
    is_deeply( Load(Dump($deep)), $deep,
        'flow: deeply nested arrays roundtrip' );

    my $complex = [
        { name => "first",  tags => ["a", "b"] },
        { name => "second", tags => ["c"] },
    ];
    is_deeply( Load(Dump($complex)), $complex,
        'flow: array of hashes with array values roundtrip' );
}

# ===== Empty collections =====
# Existing tests cover basic empty array/hash roundtrip.
# Add: nested empty containers, empty in various positions.

{
    my $nested_empty = { a => [[]], b => { x => {} } };
    is_deeply( Load(Dump($nested_empty)), $nested_empty,
        'empty: nested empty collections roundtrip' );

    my $empty_in_seq = [ [], {}, [], {} ];
    is_deeply( Load(Dump($empty_in_seq)), $empty_in_seq,
        'empty: sequence of empty collections roundtrip' );

    my $mixed_empty = { empty => [], full => [1], also_empty => {} };
    is_deeply( Load(Dump($mixed_empty)), $mixed_empty,
        'empty: mixed empty and populated collections roundtrip' );
}

# ===== Merge keys =====
# Existing tests only parse. Merge key (<<) is resolved on load with ImplicitTyping,
# so we roundtrip the resolved data.

{
    local $YAML::Syck::ImplicitTyping = 1;

    my $yaml = <<'YAML';
---
defaults: &defaults
  color: red
  size: large
item:
  <<: *defaults
  name: widget
YAML
    my $data = Load($yaml);
    my $resolved = $data->{item};

    # Resolved item should have merged keys
    is( $resolved->{color}, 'red',    'merge: resolved key from anchor' );
    is( $resolved->{name},  'widget', 'merge: explicit key preserved' );

    # Round-trip the resolved hash
    is_deeply( Load(Dump($resolved)), $resolved,
        'merge: resolved data survives roundtrip' );
}

{
    local $YAML::Syck::ImplicitTyping = 1;

    # Multiple merges
    my $yaml = <<'YAML';
---
a: &a
  x: 1
b: &b
  y: 2
c:
  <<:
    - *a
    - *b
  z: 3
YAML
    my $data = Load($yaml);
    my $resolved = $data->{c};
    is_deeply( Load(Dump($resolved)), $resolved,
        'merge: multiple merge sources roundtrip' );
}

# ===== Equals scalar =====
# Existing tests only parse. Test dump→load.

{
    is( Load(Dump("=")), "=",
        'equals: bare = scalar roundtrips' );

    my $struct = { key => "=", "=" => "value" };
    is_deeply( Load(Dump($struct)), $struct,
        'equals: = as key and value roundtrips' );
}

{
    local $YAML::Syck::ImplicitTyping = 1;

    is( Load(Dump("=")), "=",
        'equals: = roundtrips with ImplicitTyping' );
}

# ===== Directives / document markers =====
# Existing tests cover headless mode only.

{
    # Default mode: dump produces --- header, load reads it back
    my $data = { key => "value", num => 42 };
    is_deeply( Load(Dump($data)), $data,
        'directives: document with --- header roundtrips' );
}

{
    local $YAML::Syck::Headless = 1;
    my $data = { key => "value" };
    my $yaml = Dump($data);
    unlike( $yaml, qr/^---/, 'directives: headless dump omits ---' );
    is_deeply( Load($yaml), $data,
        'directives: headless output roundtrips' );
}

# ===== Anchors and aliases =====
# Verify shared references survive roundtrip.

{
    my $shared = { x => 1 };
    my $struct = [ $shared, $shared ];
    my $back = Load(Dump($struct));

    is_deeply( $back, $struct,
        'anchors: shared ref data roundtrips' );
    is( $back->[0], $back->[1],
        'anchors: shared reference identity preserved' );
}

# ===== Null values =====

{
    my $data = { a => undef, b => undef };
    my $back = Load(Dump($data));
    is_deeply( $back, $data,
        'null: undef values roundtrip' );
    ok( !defined $back->{a}, 'null: value remains undef after roundtrip' );
}

{
    my $list = [ undef, "value", undef ];
    is_deeply( Load(Dump($list)), $list,
        'null: undef in sequence roundtrips' );
}

# ===== Boolean-like strings (ImplicitTyping) =====
# Strings that look like booleans must roundtrip as strings.

{
    local $YAML::Syck::ImplicitTyping = 1;

    for my $str (qw(true false yes no on off)) {
        is( Load(Dump($str)), $str,
            "boolean string: '$str' roundtrips as string" );
    }
}

# ===== Numeric edge cases (ImplicitTyping) =====

{
    local $YAML::Syck::ImplicitTyping = 1;

    # Integers
    is( Load(Dump(0)),    0,    'numeric: zero roundtrips' );
    is( Load(Dump(42)),   42,   'numeric: positive int roundtrips' );
    is( Load(Dump(-17)),  -17,  'numeric: negative int roundtrips' );

    # Floats
    is( Load(Dump(3.14)),  3.14,  'numeric: float roundtrips' );
    is( Load(Dump(-0.5)),  -0.5,  'numeric: negative float roundtrips' );
}

# ===== Special characters in scalars =====

{
    my @specials = (
        "colon: in value",
        "hash # in value",
        "at \@ sign",
        "percent % sign",
        "pipe | char",
        "greater > than",
        "ampersand & char",
        "asterisk * char",
        "question ? mark",
        "comma, separated",
        "bracket [ open",
        "brace { open",
    );

    for my $s (@specials) {
        is( Load(Dump($s)), $s,
            "special chars: '$s' roundtrips" );
    }
}

# ===== Multiline keys =====

{
    my $data = { "multi\nline\nkey" => "value" };
    is_deeply( Load(Dump($data)), $data,
        'multiline key roundtrips' );
}

# ===== Deeply nested structure =====

{
    my $deep = {
        level1 => {
            level2 => {
                level3 => {
                    data => [1, 2, { nested => "value" }],
                },
            },
        },
    };
    is_deeply( Load(Dump($deep)), $deep,
        'deeply nested mixed structure roundtrips' );
}

done_testing();
