#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use YaraFFI;
use Test::More;

my $yara = YaraFFI->new();

ok(defined $yara, "YaraFFI object created");

my $rules = <<'RULES';
rule TestRule
{
    strings:
        $text = "abc"
        $hex = { 6A 40 68 00 30 00 00 }
    condition:
        any of them
}
RULES

ok($yara->compile($rules), "Rules compiled");

my $data = "xxabcxx";

my @events;

my $res = $yara->scan_buffer($data, sub {
    my ($info) = @_;
    push @events, $info;
});

ok($res == 0, "Scan returned 0 (success)");
ok(@events > 0, "Got at least one callback event");

# Check that at least one rule_match event was triggered
my $rule_matched = grep { $_->{event} eq 'rule_match' && $_->{rule} eq 'TestRule' } @events;
ok($rule_matched, "Rule match event for TestRule found");

# Check at least one string_match event (string id and offsets present)
my $string_match = grep { $_->{event} eq 'string_match' && defined $_->{string_id} } @events;
ok($string_match, "At least one string match event found");

done_testing;
