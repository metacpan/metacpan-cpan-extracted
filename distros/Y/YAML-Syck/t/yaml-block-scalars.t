#!/usr/bin/perl
# yaml-block-scalars.t
#
# Tests for YAML 1.0 block scalar styles:
#   - Literal block scalar (|)
#   - Folded block scalar (>)
#   - Chomping indicators (strip -, clip default, keep +)
#   - Indentation indicators
#
# Spec reference: https://yaml.org/spec/1.0/#id2566890

use strict;
use warnings;
use Test::More;
use YAML::Syck;

# --- Literal block scalar (|) ---

{
    my $yaml = <<'YAML';
---
content: |
  line one
  line two
  line three
YAML
    my $data = Load($yaml);
    is( $data->{content}, "line one\nline two\nline three\n",
        'literal block scalar preserves newlines (clip)' );
}

{
    my $yaml = <<'YAML';
---
content: |
  single line
YAML
    my $data = Load($yaml);
    is( $data->{content}, "single line\n",
        'literal block scalar single line with trailing newline' );
}

# --- Folded block scalar (>) ---

{
    my $yaml = <<'YAML';
---
content: >
  line one
  line two
  line three
YAML
    my $data = Load($yaml);
    is( $data->{content}, "line one line two line three\n",
        'folded block scalar folds newlines to spaces' );
}

{
    my $yaml = <<'YAML';
---
content: >
  paragraph one
  continues here

  paragraph two
  continues here
YAML
    my $data = Load($yaml);
    is( $data->{content}, "paragraph one continues here\nparagraph two continues here\n",
        'folded block scalar preserves blank lines as newlines' );
}

# --- Chomping: strip (|-) ---

{
    my $yaml = <<'YAML';
---
content: |-
  no trailing newline
YAML
    my $data = Load($yaml);
    is( $data->{content}, "no trailing newline",
        'literal block with strip chomping removes trailing newline' );
}

{
    my $yaml = <<'YAML';
---
content: >-
  no trailing newline
YAML
    my $data = Load($yaml);
    is( $data->{content}, "no trailing newline",
        'folded block with strip chomping removes trailing newline' );
}

# --- Chomping: keep (|+) ---

{
    my $yaml = <<'YAML';
---
content: |+
  keep trailing


YAML
    my $data = Load($yaml);
    is( $data->{content}, "keep trailing\n\n\n",
        'literal block with keep chomping preserves all trailing newlines' );
}

{
    my $yaml = <<'YAML';
---
content: >+
  keep trailing


YAML
    my $data = Load($yaml);
    is( $data->{content}, "keep trailing\n\n\n",
        'folded block with keep chomping preserves all trailing newlines' );
}

# --- Literal block in sequence ---

{
    my $yaml = <<'YAML';
---
- |
  first item
- |
  second item
YAML
    my $data = Load($yaml);
    is_deeply( $data, [ "first item\n", "second item\n" ],
        'literal block scalars in a sequence' );
}

# --- Folded block in sequence ---

{
    my $yaml = <<'YAML';
---
- >
  first
  item
- >
  second
  item
YAML
    my $data = Load($yaml);
    is_deeply( $data, [ "first item\n", "second item\n" ],
        'folded block scalars in a sequence' );
}

# --- Roundtrip: literal block content ---

{
    my $original = "line one\nline two\nline three\n";
    my $yaml = Dump({ content => $original });
    my $loaded = Load($yaml);
    is( $loaded->{content}, $original,
        'roundtrip preserves multiline string content' );
}

# --- Roundtrip: string without trailing newline ---

{
    my $original = "no trailing newline";
    my $yaml = Dump({ content => $original });
    my $loaded = Load($yaml);
    is( $loaded->{content}, $original,
        'roundtrip preserves string without trailing newline' );
}

# --- Empty block scalar ---

{
    my $yaml = <<'YAML';
---
content: |
YAML
    # An empty literal block should produce empty string or undef
    my $data = Load($yaml);
    ok( !defined($data->{content}) || $data->{content} eq '' || $data->{content} eq "\n",
        'empty literal block scalar handled' );
}

done_testing();
