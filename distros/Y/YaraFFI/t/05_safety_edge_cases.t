#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use Test::More;
use YaraFFI;
use YaraFFI::Event;

# Test 1: Large buffer scan (safety test)
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule LargeBuffer {
    strings:
        $s = "needle"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    # Create a 1MB buffer with the needle at the end
    my $large_buffer = ("x" x (1024 * 1024 - 6)) . "needle";

    my @events;
    eval {
        my $res = $yara->scan_buffer($large_buffer, sub {
            my ($event) = @_;
            push @events, $event;
        });
        is($res, 0, "Large buffer scan completed without crash");
    };

    ok(!$@, "No error scanning large buffer");
    ok(@events > 0, "Events received from large buffer scan");
}

# Test 2: Binary data scan
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule BinaryPattern {
    strings:
        $hex = { 6A 40 68 00 30 00 00 }
    condition:
        $hex
}
RULES

    ok($yara->compile($rules), "Binary rules compiled");

    # Create buffer with binary data
    my $binary_data = "prefix" . pack("H*", "6A406800300000") . "suffix";

    my @events;
    my $res = $yara->scan_buffer($binary_data, sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Binary data scan completed");
    ok(@events > 0, "Binary pattern matched");
}

# Test 3: UTF-8 and special characters
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule UTF8Test {
    strings:
        $utf = "test"
    condition:
        $utf
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    # Buffer with UTF-8 and special chars
    my $utf8_buffer = "test with émojis 🔍 and spëcial çhars";

    my @events;
    eval {
        my $res = $yara->scan_buffer($utf8_buffer, sub {
            my ($event) = @_;
            push @events, $event;
        });
        is($res, 0, "UTF-8 buffer scan completed");
    };

    ok(!$@, "No error with UTF-8 content");
}

# Test 4: Empty buffer
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule EmptyTest {
    strings:
        $s = "anything"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("", sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Empty buffer scan completed");
    is(scalar @events, 0, "No matches in empty buffer");
}

# Test 5: Callback that throws exception
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule CallbackTest {
    strings:
        $s = "test"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my $callback_called = 0;
    eval {
        my $res = $yara->scan_buffer("test data", sub {
            my ($event) = @_;
            $callback_called++;
            die "Intentional callback error";
        });
        # Scan should complete despite callback error
        is($res, 0, "Scan completes despite callback exception");
    };

    ok($callback_called > 0, "Callback was called before exception");
}

# Test 6: Multiple scans with same YaraFFI instance
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule ReusableTest {
    strings:
        $s = "target"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    # First scan
    my @events1;
    my $res1 = $yara->scan_buffer("target here", sub {
        my ($event) = @_;
        push @events1, $event;
    });

    # Second scan
    my @events2;
    my $res2 = $yara->scan_buffer("target there", sub {
        my ($event) = @_;
        push @events2, $event;
    });

    # Third scan (no match)
    my @events3;
    my $res3 = $yara->scan_buffer("no match", sub {
        my ($event) = @_;
        push @events3, $event;
    });

    is($res1, 0, "First scan successful");
    is($res2, 0, "Second scan successful");
    is($res3, 0, "Third scan successful");

    ok(@events1 > 0, "First scan had matches");
    ok(@events2 > 0, "Second scan had matches");
    is(scalar @events3, 0, "Third scan had no matches");
}

# Test 7: Recompile with different rules
{
    my $yara = YaraFFI->new();

    my $rules1 = <<'RULES';
rule FirstRule {
    strings:
        $s = "first"
    condition:
        $s
}
RULES

    ok($yara->compile($rules1), "First rules compiled");

    my @events1;
    $yara->scan_buffer("first data", sub { push @events1, $_[0] });

    my $rules2 = <<'RULES';
rule SecondRule {
    strings:
        $s = "second"
    condition:
        $s
}
RULES

    ok($yara->compile($rules2), "Rules recompiled");

    my @events2;
    $yara->scan_buffer("second data", sub { push @events2, $_[0] });

    ok(@events1 > 0, "First compilation worked");
    ok(@events2 > 0, "Second compilation worked");

    my ($rule1) = grep { $_->is_rule_match } @events1;
    my ($rule2) = grep { $_->is_rule_match } @events2;

    is($rule1->rule, 'FirstRule', "First rule matched after first compile");
    is($rule2->rule, 'SecondRule', "Second rule matched after recompile");
}

# Test 8: Rule with regex pattern
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule RegexTest {
    strings:
        $re = /test[0-9]+/
    condition:
        $re
}
RULES

    ok($yara->compile($rules), "Regex rules compiled");

    my @events;
    my $res = $yara->scan_buffer("test123 and test456", sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Regex pattern scan completed");
    ok(@events > 0, "Regex pattern matched");
}

# Test 9: Case insensitive search
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule CaseTest {
    strings:
        $s = "TeSt" nocase
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Case insensitive rules compiled");

    my @events;
    my $res = $yara->scan_buffer("test TEST TeSt", sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Case insensitive scan completed");
    ok(@events > 0, "Case insensitive match found");
}

# Test 10: Complex condition with multiple strings
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule ComplexCondition {
    strings:
        $a = "alpha"
        $b = "beta"
        $c = "gamma"
    condition:
        ($a and $b) or $c
}
RULES

    ok($yara->compile($rules), "Complex condition rules compiled");

    # Test: only alpha (should not match)
    my @events1;
    $yara->scan_buffer("alpha", sub { push @events1, $_[0] });
    is(scalar @events1, 0, "Only alpha doesn't match");

    # Test: alpha and beta (should match)
    my @events2;
    $yara->scan_buffer("alpha beta", sub { push @events2, $_[0] });
    ok(@events2 > 0, "Alpha and beta matches");

    # Test: only gamma (should match)
    my @events3;
    $yara->scan_buffer("gamma", sub { push @events3, $_[0] });
    ok(@events3 > 0, "Only gamma matches");
}

# Test 11: Reasonably long rule name (within YARA limits)
{
    my $yara = YaraFFI->new();

    # YARA typically has a 128 character limit for identifiers
    my $long_name = "Rule_" . ("A" x 100);
    my $rules = <<"RULES";
rule $long_name {
    strings:
        \$s = "test"
    condition:
        \$s
}
RULES

    ok($yara->compile($rules), "Long rule name compiled");

    my @events;
    $yara->scan_buffer("test", sub { push @events, $_[0] });

    my ($rule_event) = grep { $_->is_rule_match } @events;
    ok(defined $rule_event, "Rule with long name matched");
    like($rule_event->rule, qr/^Rule_A+$/, "Long rule name preserved");
}

# Test 12: Null bytes in buffer
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule NullByteTest {
    strings:
        $s = "test"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my $buffer_with_nulls = "test\x00\x00test\x00test";

    my @events;
    my $res = $yara->scan_buffer($buffer_with_nulls, sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Buffer with null bytes scanned");
    ok(@events > 0, "Matched despite null bytes");
}

# Test 13: Scan same buffer multiple times
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule RepeatedScan {
    strings:
        $s = "scan"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my $buffer = "scan this";

    for my $i (1..5) {
        my @events;
        my $res = $yara->scan_buffer($buffer, sub {
            push @events, $_[0];
        });

        is($res, 0, "Scan iteration $i successful");
        ok(@events > 0, "Matches found in iteration $i");
    }

    pass("Multiple scans of same buffer completed");
}

# Test 14: Invalid rule compilation (various errors)
{
    my $yara = YaraFFI->new();

    # Test 1: Syntax error (missing quote)
    my $invalid_rules1 = <<'RULES';
rule InvalidSyntax {
    strings:
        $s = "test
    condition:
        $s
}
RULES

    my $result1 = $yara->compile($invalid_rules1);
    is($result1, 0, "Invalid syntax fails to compile");

    # Test 2: Invalid identifier
    my $yara2 = YaraFFI->new();
    my $invalid_rules2 = <<'RULES';
rule 123InvalidName {
    strings:
        $s = "test"
    condition:
        $s
}
RULES

    my $result2 = $yara2->compile($invalid_rules2);
    is($result2, 0, "Invalid rule name fails to compile");

    # Test 3: Excessively long rule name (over YARA limit)
    my $yara3 = YaraFFI->new();
    my $too_long_name = "Rule_" . ("X" x 300);
    my $invalid_rules3 = <<"RULES";
rule $too_long_name {
    strings:
        \$s = "test"
    condition:
        \$s
}
RULES

    my $result3 = $yara3->compile($invalid_rules3);
    is($result3, 0, "Excessively long rule name fails to compile");
}

# Test 15: Event object edge cases
{
    # Event with undefined values
    my $event1 = YaraFFI::Event->new(
        event => 'rule_match',
        rule  => 'Test',
    );

    is($event1->metadata, undef, "Undefined metadata returns undef");
    is_deeply($event1->offsets, [], "Undefined offsets returns empty array");
    is($event1->string_id, undef, "Undefined string_id returns undef");

    # Event with null string_id
    my $event2 = YaraFFI::Event->new(
        event     => 'string_match',
        rule      => 'Test',
        string_id => undef,
    );

    is($event2->string_id, undef, "Null string_id preserved");
}

# Test 16: Concurrent rule matching
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule Rule1 {
    strings:
        $s = "one"
    condition:
        $s
}

rule Rule2 {
    strings:
        $s = "two"
    condition:
        $s
}

rule Rule3 {
    strings:
        $s = "three"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Multiple rules compiled");

    my @events;
    my $res = $yara->scan_buffer("one two three", sub {
        push @events, $_[0];
    });

    is($res, 0, "Scan completed");

    my @rule_events = grep { $_->is_rule_match } @events;
    is(scalar @rule_events, 3, "All three rules matched");

    my %matched_rules = map { $_->rule => 1 } @rule_events;
    ok($matched_rules{Rule1}, "Rule1 matched");
    ok($matched_rules{Rule2}, "Rule2 matched");
    ok($matched_rules{Rule3}, "Rule3 matched");
}

# Test 17: Metadata and offsets with no match
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule NoMatchTest {
    meta:
        author = "Test"
    strings:
        $s = "notfound"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("different content", sub {
        push @events, $_[0];
    }, enable_metadata => 1, enable_offsets => 1);

    is($res, 0, "Scan completed");
    is(scalar @events, 0, "No events when no match");
}

# Test 18: Memory cleanup test
{
    for my $i (1..10) {
        my $yara = YaraFFI->new();

        my $rules = <<'RULES';
rule MemTest {
    strings:
        $s = "test"
    condition:
        $s
}
RULES

        $yara->compile($rules);

        my @events;
        $yara->scan_buffer("test data", sub {
            push @events, $_[0];
        });

        # Let $yara go out of scope
    }

    pass("Multiple YaraFFI instances created and destroyed without issues");
}

done_testing;
