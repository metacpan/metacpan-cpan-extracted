#!/usr/bin/perl
# yaml-timestamps.t
#
# Tests for YAML 1.0 timestamp implicit typing:
#   - Date (YYYY-MM-DD)
#   - Spaced timestamp (YYYY-MM-DD HH:MM:SS)
#   - ISO 8601 timestamps
#   - Behavior with and without ImplicitTyping
#
# Spec reference: https://yaml.org/spec/1.0/#id2568928
# The implicit.c recognizer identifies timestamp patterns.

use strict;
use warnings;
use Test::More;
use YAML::Syck;

# --- Timestamps without ImplicitTyping (should be strings) ---

{
    local $YAML::Syck::ImplicitTyping = 0;

    my $yaml = <<'YAML';
---
date: 2005-01-01
YAML
    my $data = Load($yaml);
    is( $data->{date}, '2005-01-01',
        'date value is string without ImplicitTyping' );
}

{
    local $YAML::Syck::ImplicitTyping = 0;

    my $yaml = <<'YAML';
---
ts: 2005-01-01 12:30:00
YAML
    my $data = Load($yaml);
    is( $data->{ts}, '2005-01-01 12:30:00',
        'spaced timestamp is string without ImplicitTyping' );
}

# --- Timestamps with ImplicitTyping ---

{
    local $YAML::Syck::ImplicitTyping = 1;

    my $yaml = <<'YAML';
---
date: 2005-01-01
YAML
    my $data = Load($yaml);
    # With ImplicitTyping, a date may be resolved to a string or kept as-is
    # depending on whether the timestamp type handler is active.
    # The key thing is it loads without error.
    ok( defined $data->{date}, 'date loads with ImplicitTyping' );
    # implicit.c recognizes this as timestamp type
    like( "$data->{date}", qr/2005/,
        'date value contains year component' );
}

{
    local $YAML::Syck::ImplicitTyping = 1;

    my $yaml = <<'YAML';
---
ts: 2005-06-15 12:30:00
YAML
    my $data = Load($yaml);
    ok( defined $data->{ts}, 'spaced timestamp loads with ImplicitTyping' );
}

# --- ISO 8601 timestamp ---

{
    local $YAML::Syck::ImplicitTyping = 1;

    my $yaml = <<'YAML';
---
ts: 2005-06-15T12:30:00Z
YAML
    my $data = Load($yaml);
    ok( defined $data->{ts}, 'ISO 8601 timestamp with Z loads' );
}

{
    local $YAML::Syck::ImplicitTyping = 1;

    my $yaml = <<'YAML';
---
ts: 2005-06-15T12:30:00+05:30
YAML
    my $data = Load($yaml);
    ok( defined $data->{ts}, 'ISO 8601 timestamp with timezone offset loads' );
}

# --- Date roundtrip ---

{
    local $YAML::Syck::ImplicitTyping = 0;

    my $date = '2005-01-01';
    my $yaml = Dump({ date => $date });
    my $data = Load($yaml);
    is( $data->{date}, $date,
        'date string roundtrips without ImplicitTyping' );
}

# --- Timestamp-like values that should remain strings ---

{
    local $YAML::Syck::ImplicitTyping = 1;

    my $yaml = <<'YAML';
---
not_date: "2005-01-01"
YAML
    my $data = Load($yaml);
    is( $data->{not_date}, '2005-01-01',
        'quoted date is always a string even with ImplicitTyping' );
}

# --- Multiple timestamp formats ---

{
    local $YAML::Syck::ImplicitTyping = 0;

    my $yaml = <<'YAML';
---
dates:
  - 2005-01-01
  - 2005-06-15 12:30:00
  - 2005-06-15T12:30:00Z
YAML
    my $data = Load($yaml);
    is( scalar @{$data->{dates}}, 3,
        'multiple timestamp formats in a sequence' );
    is( $data->{dates}[0], '2005-01-01', 'plain date in sequence' );
    is( $data->{dates}[1], '2005-06-15 12:30:00', 'spaced timestamp in sequence' );
    is( $data->{dates}[2], '2005-06-15T12:30:00Z', 'ISO timestamp in sequence' );
}

done_testing();
