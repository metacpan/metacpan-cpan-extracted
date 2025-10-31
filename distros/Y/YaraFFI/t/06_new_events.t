#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use Test::More;
use YaraFFI;
use YaraFFI::Event;

# Test 1: scan_finished event - default behavior (disabled)
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule TestRule {
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
    });

    is($res, 0, "Scan completed");

    my @finished_events = grep { $_->{event} eq 'scan_finished' } @events;
    is(scalar @finished_events, 0, "No scan_finished event by default");
}

# Test 2: scan_finished event - explicitly enabled
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule TestRule {
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
    }, emit_finished_events => 1);

    is($res, 0, "Scan completed");

    my @finished_events = grep { $_->{event} eq 'scan_finished' } @events;
    is(scalar @finished_events, 1, "scan_finished event emitted when enabled");

    my $finished = $finished_events[0];
    is($finished->{event}, 'scan_finished', "Event type is scan_finished");
}

# Test 3: scan_finished event - with no matches
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule NoMatch {
    strings:
        $s = "notfound"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("different data", sub {
        my ($event) = @_;
        push @events, $event;
    }, emit_finished_events => 1);

    is($res, 0, "Scan completed");

    my @finished_events = grep { $_->{event} eq 'scan_finished' } @events;
    is(scalar @finished_events, 1, "scan_finished event emitted even with no matches");
    is(scalar @events, 1, "Only scan_finished event emitted");
}

# Test 4: scan_finished event - order of events
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule OrderTest {
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
    }, emit_finished_events => 1);

    is($res, 0, "Scan completed");
    ok(scalar @events >= 2, "At least 2 events (rule_match + scan_finished)");

    # scan_finished should be the last event
    is($events[-1]->{event}, 'scan_finished', "scan_finished is the last event");
}

# Test 5: rule_not_match event - default behavior (disabled)
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule MatchRule {
    strings:
        $a = "match"
    condition:
        $a
}

rule NoMatchRule {
    strings:
        $b = "nomatch"
    condition:
        $b
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("match this", sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Scan completed");

    my @not_match_events = grep { $_->{event} eq 'rule_not_match' } @events;
    is(scalar @not_match_events, 0, "No rule_not_match events by default");
}

# Test 6: rule_not_match event - explicitly enabled
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule MatchRule {
    strings:
        $a = "match"
    condition:
        $a
}

rule NoMatchRule {
    strings:
        $b = "nomatch"
    condition:
        $b
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("match this", sub {
        my ($event) = @_;
        push @events, $event;
    }, emit_not_match_events => 1);

    is($res, 0, "Scan completed");

    my @match_events = grep { $_->{event} eq 'rule_match' } @events;
    my @not_match_events = grep { $_->{event} eq 'rule_not_match' } @events;

    is(scalar @match_events, 1, "One rule matched");
    is(scalar @not_match_events, 1, "One rule did not match");

    is($match_events[0]->{rule}, 'MatchRule', "MatchRule matched");
    is($not_match_events[0]->{rule}, 'NoMatchRule', "NoMatchRule did not match");
}

# Test 7: rule_not_match event - all rules match
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule Rule1 {
    strings:
        $a = "alpha"
    condition:
        $a
}

rule Rule2 {
    strings:
        $b = "beta"
    condition:
        $b
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("alpha beta", sub {
        my ($event) = @_;
        push @events, $event;
    }, emit_not_match_events => 1);

    is($res, 0, "Scan completed");

    my @match_events = grep { $_->{event} eq 'rule_match' } @events;
    my @not_match_events = grep { $_->{event} eq 'rule_not_match' } @events;

    is(scalar @match_events, 2, "Both rules matched");
    is(scalar @not_match_events, 0, "No rules failed to match");
}

# Test 8: rule_not_match event - no rules match
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule Rule1 {
    strings:
        $a = "alpha"
    condition:
        $a
}

rule Rule2 {
    strings:
        $b = "beta"
    condition:
        $b
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("gamma delta", sub {
        my ($event) = @_;
        push @events, $event;
    }, emit_not_match_events => 1);

    is($res, 0, "Scan completed");

    my @match_events = grep { $_->{event} eq 'rule_match' } @events;
    my @not_match_events = grep { $_->{event} eq 'rule_not_match' } @events;

    is(scalar @match_events, 0, "No rules matched");
    is(scalar @not_match_events, 2, "Both rules did not match");

    my %not_matched = map { $_->{rule} => 1 } @not_match_events;
    ok($not_matched{Rule1}, "Rule1 did not match");
    ok($not_matched{Rule2}, "Rule2 did not match");
}

# Test 9: import_module event - default behavior (disabled)
{
    my $yara = YaraFFI->new();

    # Note: This test might not trigger import events depending on YARA setup
    # but we test that the option doesn't break anything
    my $rules = <<'RULES';
rule SimpleRule {
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
    });

    is($res, 0, "Scan completed");

    my @import_events = grep { $_->{event} eq 'import_module' } @events;
    is(scalar @import_events, 0, "No import_module events by default");
}

# Test 10: import_module event - explicitly enabled
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule SimpleRule {
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
    }, emit_import_events => 1);

    is($res, 0, "Scan completed with import events enabled");

    # Note: import events may or may not occur depending on YARA configuration
    # We just verify enabling the option doesn't break anything
    pass("Scan with import events enabled completed successfully");
}

# Test 11: Combine all new event types
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule MatchingRule {
    strings:
        $a = "find"
    condition:
        $a
}

rule NonMatchingRule {
    strings:
        $b = "nothere"
    condition:
        $b
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("find this", sub {
        my ($event) = @_;
        push @events, $event;
    },
        emit_not_match_events => 1,
        emit_import_events => 1,
        emit_finished_events => 1
    );

    is($res, 0, "Scan completed");

    my %event_types;
    for my $event (@events) {
        $event_types{$event->{event}}++;
    }

    ok($event_types{rule_match}, "rule_match event present");
    ok($event_types{rule_not_match}, "rule_not_match event present");
    ok($event_types{scan_finished}, "scan_finished event present");

    # scan_finished should be last
    is($events[-1]->{event}, 'scan_finished', "scan_finished is last event");
}

# Test 12: YaraFFI::Event objects for new event types
{
    # Test scan_finished event object
    my $finished_event = YaraFFI::Event->new(
        event => 'scan_finished',
    );

    ok(defined $finished_event, "scan_finished event object created");
    is($finished_event->event, 'scan_finished', "Event type correct");
    ok(!$finished_event->is_rule_match, "Not a rule_match event");
    ok(!$finished_event->is_string_match, "Not a string_match event");

    # Test rule_not_match event object
    my $not_match_event = YaraFFI::Event->new(
        event => 'rule_not_match',
        rule  => 'FailedRule',
    );

    ok(defined $not_match_event, "rule_not_match event object created");
    is($not_match_event->event, 'rule_not_match', "Event type correct");
    is($not_match_event->rule, 'FailedRule', "Rule name accessible");

    # Test import_module event object
    my $import_event = YaraFFI::Event->new(
        event       => 'import_module',
        module_name => 'pe',
    );

    ok(defined $import_event, "import_module event object created");
    is($import_event->event, 'import_module', "Event type correct");
    is($import_event->{module_name}, 'pe', "Module name accessible");
}

# Test 13: Event type consistency across multiple scans
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule TestRule {
    strings:
        $s = "scan"
    condition:
        $s
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    for my $iteration (1..3) {
        my @events;
        my $res = $yara->scan_buffer("scan $iteration", sub {
            my ($event) = @_;
            push @events, $event;
        }, emit_finished_events => 1);

        is($res, 0, "Scan iteration $iteration completed");

        my @finished = grep { $_->{event} eq 'scan_finished' } @events;
        is(scalar @finished, 1, "scan_finished event in iteration $iteration");
        is($events[-1]->{event}, 'scan_finished', "scan_finished is last in iteration $iteration");
    }
}

# Test 14: All event flags disabled
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule Match {
    strings:
        $a = "yes"
    condition:
        $a
}

rule NoMatch {
    strings:
        $b = "no"
    condition:
        $b
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("yes", sub {
        my ($event) = @_;
        push @events, $event;
    },
        emit_string_events => 0,
        emit_not_match_events => 0,
        emit_import_events => 0,
        emit_finished_events => 0
    );

    is($res, 0, "Scan completed");

    # Should only have rule_match event
    is(scalar @events, 1, "Only one event with all flags disabled");
    is($events[0]->{event}, 'rule_match', "Only rule_match event present");
}

# Test 15: Event callback receives proper event objects
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

    my $received_objects = 0;
    my $res = $yara->scan_buffer("test", sub {
        my ($event) = @_;

        # Check that we receive proper event objects
        if (ref($event) eq 'YaraFFI::Event') {
            $received_objects++;
        }
    }, emit_finished_events => 1);

    is($res, 0, "Scan completed");
    ok($received_objects >= 2, "Received YaraFFI::Event objects");
}

# Test 16: Large number of rules with not_match events
{
    my $yara = YaraFFI->new();

    # Create 10 rules, only one will match
    my $rules = '';
    for my $i (1..10) {
        $rules .= <<"RULE";
rule Rule$i {
    strings:
        \$s$i = "pattern$i"
    condition:
        \$s$i
}
RULE
    }

    ok($yara->compile($rules), "10 rules compiled");

    my @events;
    my $res = $yara->scan_buffer("pattern5", sub {
        my ($event) = @_;
        push @events, $event;
    }, emit_not_match_events => 1);

    is($res, 0, "Scan completed");

    my @match = grep { $_->{event} eq 'rule_match' } @events;
    my @not_match = grep { $_->{event} eq 'rule_not_match' } @events;

    is(scalar @match, 1, "One rule matched");
    is(scalar @not_match, 9, "Nine rules did not match");
    is($match[0]->{rule}, 'Rule5', "Correct rule matched");
}

# Test 17: Event to_hash method for new event types
{
    my $finished_event = YaraFFI::Event->new(
        event => 'scan_finished',
    );

    my $hash = $finished_event->to_hash;
    ok(ref $hash eq 'HASH', "to_hash returns hash");
    is($hash->{event}, 'scan_finished', "Hash contains event type");

    my $not_match_event = YaraFFI::Event->new(
        event => 'rule_not_match',
        rule  => 'TestRule',
    );

    my $hash2 = $not_match_event->to_hash;
    is($hash2->{event}, 'rule_not_match', "Hash contains event type");
    is($hash2->{rule}, 'TestRule', "Hash contains rule name");
}

# Test 18: Empty buffer with finished event
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
    }, emit_finished_events => 1);

    is($res, 0, "Empty buffer scan completed");
    is(scalar @events, 1, "Only scan_finished event for empty buffer");
    is($events[0]->{event}, 'scan_finished', "scan_finished event emitted");
}

# Test 19: Verify event order with all types enabled
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule Alpha {
    strings:
        $a = "alpha"
    condition:
        $a
}

rule Beta {
    strings:
        $b = "beta"
    condition:
        $b
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    my @events;
    my $res = $yara->scan_buffer("alpha", sub {
        my ($event) = @_;
        push @events, $event;
    },
        emit_not_match_events => 1,
        emit_finished_events => 1
    );

    is($res, 0, "Scan completed");

    # Verify scan_finished is always last
    is($events[-1]->{event}, 'scan_finished', "scan_finished is always last event");

    # Verify we have match, not_match, and finished events
    my %types = map { $_->{event} => 1 } @events;
    ok($types{rule_match}, "Has rule_match event");
    ok($types{rule_not_match}, "Has rule_not_match event");
    ok($types{scan_finished}, "Has scan_finished event");
}

# Test 20: Backward compatibility - default behavior unchanged
{
    my $yara = YaraFFI->new();

    my $rules = <<'RULES';
rule BackwardCompat {
    strings:
        $s = "test"
    condition:
        $s
}

rule NoMatch {
    strings:
        $n = "nomatch"
    condition:
        $n
}
RULES

    ok($yara->compile($rules), "Rules compiled");

    # Default scan should work exactly as before
    my @events;
    my $res = $yara->scan_buffer("test", sub {
        my ($event) = @_;
        push @events, $event;
    });

    is($res, 0, "Scan completed");

    # Should only have rule_match and string_match events
    my %types = map { $_->{event} => 1 } @events;
    ok($types{rule_match}, "Has rule_match (backward compat)");
    ok($types{string_match}, "Has string_match (backward compat)");
    ok(!$types{rule_not_match}, "No rule_not_match by default (backward compat)");
    ok(!$types{scan_finished}, "No scan_finished by default (backward compat)");
}

done_testing;
