#!/usr/bin/perl
# yaml-comments.t
#
# Tests for YAML 1.0 comment handling:
#   - Full-line comments
#   - Inline comments (after values)
#   - Comments in various positions
#
# Spec reference: https://yaml.org/spec/1.0/#id2564201

use strict;
use warnings;
use Test::More;
use YAML::Syck;

# --- Full-line comments ---

{
    my $yaml = <<'YAML';
---
# This is a comment
key: value
YAML
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        'full-line comment before a mapping entry' );
}

{
    my $yaml = <<'YAML';
---
key1: value1
# comment between entries
key2: value2
YAML
    my $data = Load($yaml);
    is( $data->{key1}, 'value1', 'value before comment' );
    is( $data->{key2}, 'value2', 'value after comment' );
}

# --- Inline comments ---

{
    my $yaml = <<'YAML';
---
key: value # inline comment
YAML
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        'inline comment after mapping value' );
}

# --- Comments in sequences ---

{
    my $yaml = <<'YAML';
---
# comment before sequence
- item1
# comment between items
- item2
- item3  # inline comment
YAML
    my $data = Load($yaml);
    is_deeply( $data, [ 'item1', 'item2', 'item3' ],
        'comments in block sequences' );
}

# --- Comment-only lines at top ---

{
    my $yaml = <<'YAML';
# file-level comment
---
key: value
YAML
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        'comment before document start marker' );
}

# --- Multiple consecutive comments ---

{
    my $yaml = <<'YAML';
---
# comment 1
# comment 2
# comment 3
key: value
YAML
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        'multiple consecutive comment lines' );
}

# --- Comments in nested structures ---

{
    my $yaml = <<'YAML';
---
outer:
  # comment in nested mapping
  inner: value
YAML
    my $data = Load($yaml);
    is( $data->{outer}{inner}, 'value',
        'comment inside nested mapping' );
}

# --- Comment after document start ---

{
    my $yaml = <<'YAML';
--- # document comment
key: value
YAML
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        'inline comment on document start marker' );
}

done_testing();
