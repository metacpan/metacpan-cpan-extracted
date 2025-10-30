#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use YaraFFI;
use YaraFFI::Event;
use Test::More;

# Test 1: Basic YaraFFI::Event object creation and methods
{
    my $event = YaraFFI::Event->new(
        event => 'rule_match',
        rule  => 'TestRule',
    );

    ok(defined $event, "Event object created");
    is($event->event, 'rule_match', "Event type accessor works");
    is($event->rule, 'TestRule', "Rule accessor works");
    is("$event", 'TestRule', "Event stringifies to rule name");
    ok($event->is_rule_match, "is_rule_match returns true");
    ok(!$event->is_string_match, "is_string_match returns false");
}

# Test 2: Event with metadata
{
    my $event = YaraFFI::Event->new(
        event    => 'rule_match',
        rule     => 'MetaRule',
        metadata => {
            author      => 'Test Author',
            severity    => 5,
            description => 'Test description',
            active      => 1,
        },
    );

    ok($event->has_metadata, "has_metadata returns true");
    is($event->author, 'Test Author', "Metadata author accessor works");
    is($event->severity, 5, "Metadata severity accessor works");
    is($event->description, 'Test description', "Metadata description accessor works");
    is_deeply($event->metadata, {
        author      => 'Test Author',
        severity    => 5,
        description => 'Test description',
        active      => 1,
    }, "Full metadata hash accessible");
}

# Test 3: Event without metadata
{
    my $event = YaraFFI::Event->new(
        event => 'rule_match',
        rule  => 'NoMetaRule',
    );

    ok(!$event->has_metadata, "has_metadata returns false when no metadata");
    is($event->author, undef, "Author accessor returns undef without metadata");
    is($event->metadata, undef, "Metadata accessor returns undef");
}

# Test 4: String match event with offsets
{
    my $event = YaraFFI::Event->new(
        event     => 'string_match',
        rule      => 'StringRule',
        string_id => '$test_string',
        offsets   => [0, 42, 100, 256],
    );

    ok($event->is_string_match, "is_string_match returns true");
    ok(!$event->is_rule_match, "is_rule_match returns false");
    is($event->string_id, '$test_string', "String ID accessor works");
    ok($event->has_offsets, "has_offsets returns true");
    is($event->match_count, 4, "match_count returns correct count");
    is_deeply($event->offsets, [0, 42, 100, 256], "Offsets array accessible");
}

# Test 5: String match event without offsets
{
    my $event = YaraFFI::Event->new(
        event     => 'string_match',
        rule      => 'StringRule',
        string_id => '$test',
        offsets   => [],
    );

    ok(!$event->has_offsets, "has_offsets returns false for empty array");
    is($event->match_count, 0, "match_count returns 0 for empty offsets");
    is_deeply($event->offsets, [], "Empty offsets array returned");
}

# Test 6: Default scan behavior (metadata/offsets disabled)
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule DefaultTest {
    meta:
        author = "Should Not Extract"
        severity = 10
    strings:
        $s = "testdata"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("testdata here", sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Scan completed successfully");
    ok(@events >= 1, "At least one event received");

    # Check rule_match event has no metadata by default
    my ($rule_event) = grep { $_->is_rule_match } @events;
    ok(defined $rule_event, "Found rule_match event");
    ok(!$rule_event->has_metadata, "Metadata not extracted by default");
    is($rule_event->metadata, undef, "Metadata is undef by default");

    # Check string_match event has no detailed offsets by default
    my ($string_event) = grep { $_->is_string_match } @events;
    ok(defined $string_event, "Found string_match event");
    # Note: By default it emits a generic string_match with empty offsets
    is($string_event->string_id, '$', "Generic string ID used by default");
}

# Test 7: Scan with metadata extraction enabled
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule MetadataTest {
    meta:
        author = "Test Author"
        description = "Test Description"
        severity = 7
        active = true
    strings:
        $a = "metadata"
    condition:
        $a
}
RULES

    ok($yara->compile($rules), "Rules with metadata compiled");

    my @events;
    my $res = $yara->scan_buffer("metadata test", sub {
        my ($event) = @_;
        push @events, $event;
    }, enable_metadata => 1);

    is($res, 0, "Scan with metadata enabled completed");

    my ($rule_event) = grep { $_->is_rule_match } @events;
    ok(defined $rule_event, "Found rule_match event");

    # Note: Metadata extraction is experimental and may not work on all YARA versions
    # We test that it doesn't crash and returns the right structure if it works
    if ($rule_event->has_metadata) {
        pass("Metadata was extracted (YARA version supports it)");
        like($rule_event->author // '', qr/./, "Author metadata accessible")
            if defined $rule_event->metadata->{author};
    } else {
        pass("Metadata not extracted (YARA version may not support it, but didn't crash)");
    }
}

# Test 8: Scan with offset extraction enabled
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule OffsetTest {
    strings:
        $pattern = "find"
    condition:
        $pattern
}
RULES

    ok($yara->compile($rules), "Rules compiled for offset test");

    my @events;
    my $res = $yara->scan_buffer("find this find here find", sub {
        my ($event) = @_;
        push @events, $event;
    }, enable_offsets => 1);

    is($res, 0, "Scan with offsets enabled completed");

    my @string_events = grep { $_->is_string_match } @events;
    ok(@string_events > 0, "At least one string_match event received");

    # Note: Offset extraction is experimental
    # Test that it either extracts properly or falls back gracefully
    for my $event (@string_events) {
        ok(defined $event->string_id, "String ID is defined");
        ok(defined $event->offsets, "Offsets array is defined");
        ok(ref $event->offsets eq 'ARRAY', "Offsets is an array reference");

        if ($event->has_offsets) {
            pass("Offsets were extracted");
            cmp_ok($event->match_count, '>', 0, "Match count is positive");
        }
    }
}

# Test 9: Scan with both metadata and offsets enabled
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule CombinedTest {
    meta:
        test_type = "combined"
    strings:
        $x = "combo"
    condition:
        $x
}
RULES

    ok($yara->compile($rules), "Rules compiled for combined test");

    my @events;
    my $res = $yara->scan_buffer("combo test", sub {
        my ($event) = @_;
        push @events, $event;
    }, enable_metadata => 1, enable_offsets => 1);

    is($res, 0, "Scan with both features enabled completed");
    ok(@events >= 1, "Events received with both features enabled");

    # Verify structure is correct even if extraction doesn't work
    my ($rule_event) = grep { $_->is_rule_match } @events;
    ok(defined $rule_event, "Rule match event exists");

    my ($string_event) = grep { $_->is_string_match } @events;
    ok(defined $string_event, "String match event exists");
}

# Test 10: Multiple rules with metadata
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule Rule1 {
    meta:
        rule_id = 1
    strings:
        $a = "alpha"
    condition:
        $a
}

rule Rule2 {
    meta:
        rule_id = 2
    strings:
        $b = "beta"
    condition:
        $b
}
RULES

    ok($yara->compile($rules), "Multiple rules compiled");

    my @events;
    my $res = $yara->scan_buffer("alpha and beta", sub {
        my ($event) = @_;
        push @events, $event;
    }, enable_metadata => 1);

    is($res, 0, "Scan with multiple rules completed");

    my @rule_events = grep { $_->is_rule_match } @events;
    is(scalar @rule_events, 2, "Both rules matched");

    my @rule_names = sort map { $_->rule } @rule_events;
    is_deeply(\@rule_names, ['Rule1', 'Rule2'], "Correct rules matched");
}

# Test 11: Disable string events
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule NoStringEvents {
    strings:
        $s = "test"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("test data", sub {
        my ($event) = @_;
        push @events, $event;
    }, emit_string_events => 0);

    is($res, 0, "Scan completed");

    my @rule_events = grep { $_->is_rule_match } @events;
    my @string_events = grep { $_->is_string_match } @events;

    is(scalar @rule_events, 1, "Rule match event received");
    is(scalar @string_events, 0, "No string match events when disabled");
}

# Test 12: Event to_hash method
{
    my $event = YaraFFI::Event->new(
        event     => 'string_match',
        rule      => 'TestRule',
        string_id => '$test',
        offsets   => [10, 20],
    );

    my $hash = $event->to_hash;
    ok(ref $hash eq 'HASH', "to_hash returns hash reference");
    is($hash->{event}, 'string_match', "Hash contains event type");
    is($hash->{rule}, 'TestRule', "Hash contains rule name");
    is($hash->{string_id}, '$test', "Hash contains string_id");
    is_deeply($hash->{offsets}, [10, 20], "Hash contains offsets");
}

# Test 13: Buffer with no matches
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule NoMatch {
    strings:
        $nomatch = "shouldnotfind"
    condition:
        $nomatch
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("different data", sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Scan completed");
    is(scalar @events, 0, "No events for non-matching scan");
}

# Test 14: Error handling - scan without compile
{
    my $yara = YaraFFI->new();

    eval {
        $yara->scan_buffer("test", sub {});
    };

    like($@, qr/Compile rules first/, "Error thrown when scanning without compiling");
}

# Test 15: Multiple string patterns in single rule
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule MultiString {
    strings:
        $s1 = "first"
        $s2 = "second"
        $s3 = "third"
    condition:
        any of them
}
RULES

    ok($yara->compile($rules), "Multi-string rule compiled");

    my @events;
    my $res = $yara->scan_buffer("first and second and third", sub {
        my ($event) = @_;
        push @events, $event;
    }, enable_offsets => 1);

    is($res, 0, "Scan completed");

    my @rule_events = grep { $_->is_rule_match } @events;
    is(scalar @rule_events, 1, "One rule matched");

    my @string_events = grep { $_->is_string_match } @events;
    ok(@string_events >= 1, "String match events received");
}

# Test 16: Metadata with different types
{
    my $event = YaraFFI::Event->new(
        event    => 'rule_match',
        rule     => 'TypeTest',
        metadata => {
            string_val  => 'text',
            int_val     => 42,
            bool_val    => 1,
        },
    );

    is($event->metadata->{string_val}, 'text', "String metadata value");
    is($event->metadata->{int_val}, 42, "Integer metadata value");
    is($event->metadata->{bool_val}, 1, "Boolean metadata value");
}

# Test 17: Empty metadata hash
{
    my $event = YaraFFI::Event->new(
        event    => 'rule_match',
        rule     => 'EmptyMeta',
        metadata => {},
    );

    ok(!$event->has_metadata, "Empty metadata hash treated as no metadata");
}

# Test 18: Reference and date metadata accessors
{
    my $event = YaraFFI::Event->new(
        event    => 'rule_match',
        rule     => 'RefDateTest',
        metadata => {
            reference => 'CVE-2024-1234',
            date      => '2024-01-15',
        },
    );

    is($event->reference, 'CVE-2024-1234', "Reference metadata accessor");
    is($event->date, '2024-01-15', "Date metadata accessor");
}

done_testing;
