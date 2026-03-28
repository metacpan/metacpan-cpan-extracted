#!/usr/bin/perl
# yaml-merge-key.t
#
# Tests for YAML 1.0 merge key (<<):
#   - Basic merge from anchored mapping
#   - Multiple merges
#   - Override precedence (explicit keys win over merged keys)
#
# Spec reference: https://yaml.org/spec/1.0/ (merge key type)
# The merge key is recognized by implicit.c as type "merge".

use strict;
use warnings;
use Test::More;
use YAML::Syck;

$YAML::Syck::ImplicitTyping = 1;

# --- Basic merge ---

{
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
    is( $data->{item}{name}, 'widget',
        'merge: explicit key present' );
    is( $data->{item}{color}, 'red',
        'merge: inherited key from anchor' );
    is( $data->{item}{size}, 'large',
        'merge: second inherited key from anchor' );
}

# --- Merge with override ---

{
    my $yaml = <<'YAML';
---
defaults: &defaults
  color: red
  size: large

item:
  <<: *defaults
  color: blue
  name: widget
YAML
    my $data = Load($yaml);
    is( $data->{item}{color}, 'blue',
        'merge override: explicit key wins over merged key' );
    is( $data->{item}{name}, 'widget',
        'merge override: additional explicit key present' );

    is( $data->{item}{size}, 'large',
        'merge override: non-overridden key still inherited' );
}

# --- Merge from multiple mappings ---

{
    my $yaml = <<'YAML';
---
base1: &base1
  a: 1
  b: 2

base2: &base2
  c: 3
  d: 4

combined:
  <<: [*base1, *base2]
  e: 5
YAML
    my $data = Load($yaml);

    is( $data->{combined}{e}, 5, 'multi-merge: explicit key present' );

    is( $data->{combined}{a}, 1, 'multi-merge: key from first base' );
    is( $data->{combined}{b}, 2, 'multi-merge: all keys from first base' );
    is( $data->{combined}{c}, 3, 'multi-merge: key from second base' );
    is( $data->{combined}{d}, 4, 'multi-merge: all keys from second base' );
}

# --- Sequence merge: first mapping wins for duplicate keys ---

{
    my $yaml = <<'YAML';
---
base1: &base1
  x: from-first
  w: from-first

base2: &base2
  x: from-second
  z: from-second

merged:
  <<: [*base1, *base2]
YAML
    my $data = Load($yaml);
    is( $data->{merged}{x}, 'from-first',
        'multi-merge precedence: first mapping wins for duplicate keys' );
    is( $data->{merged}{w}, 'from-first',
        'multi-merge precedence: unique key from first' );
    is( $data->{merged}{z}, 'from-second',
        'multi-merge precedence: unique key from second' );
}

# --- Merge does not store << as a key ---

{
    my $yaml = <<'YAML';
---
defaults: &defaults
  a: 1

item:
  <<: *defaults
  b: 2
YAML
    my $data = Load($yaml);
    ok( !exists $data->{item}{'<<'},
        'merge: << key is not stored in resulting hash' );
    is_deeply( [sort keys %{$data->{item}}], ['a', 'b'],
        'merge: only expected keys present' );
}

# --- Merge key without ImplicitTyping ---

{
    local $YAML::Syck::ImplicitTyping = 0;

    my $yaml = <<'YAML';
---
defaults: &defaults
  color: red

item:
  <<: *defaults
  name: widget
YAML
    my $data = Load($yaml);
    # Without ImplicitTyping, << is stored as a literal key
    ok( defined $data->{item}, 'no implicit typing: structure loads' );
    ok( exists $data->{item}{'<<'},
        'no implicit typing: << stored as literal key' );
    ok( !defined $data->{item}{color},
        'no implicit typing: merged keys not expanded' );
}

# --- << as a plain string value (not merge context) ---

{
    my $yaml = <<'YAML';
---
operator: <<
YAML
    my $data = Load($yaml);
    # When << is a value (not a mapping key with alias), it should still be parsed
    ok( defined $data->{operator}, '<< as a plain value is defined' );
}

done_testing();
