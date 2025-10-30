#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use YaraFFI;
use Test::More;
use File::Temp qw(tempfile);

my $yara = YaraFFI->new();

ok(defined $yara, "YaraFFI object created");

# Compile multiple rules
my $rules = <<'RULES';
rule Rule1
{
    strings:
        $a = "hello"
    condition:
        $a
}
rule Rule2
{
    strings:
        $b = { 6A 40 68 00 30 00 00 }
    condition:
        $b
}
RULES

ok($yara->compile($rules), "Compiled multiple rules");

# Scan a buffer with match
my $buffer = "xxhello world";

my @events;
my $res = $yara->scan_buffer($buffer, sub {
    my ($info) = @_;
    push @events, $info;
});

is($res, 0, "scan_buffer succeeded");
ok(@events > 0, "Got callback events scanning buffer");

# Check for Rule1 match event
my $rule1_match = grep { $_->{event} eq 'rule_match' && $_->{rule} eq 'Rule1' } @events;
ok($rule1_match, "Found rule_match for Rule1");

# Check string_match event
my $string_match = grep { $_->{event} eq 'string_match' && defined $_->{string_id} } @events;
ok($string_match, "Found string_match event");

# Scan a file with match
my ($fh, $filename) = tempfile(SUFFIX => '.txt', UNLINK => 1);
# Write exact bytes that match { 6A 40 68 00 30 00 00 }
print $fh "junk " . pack("H*", "6A406800300000");
close $fh;

@events = ();
$res = $yara->scan_file($filename, sub {
    my ($info) = @_;
    push @events, $info;
});

is($res, 0, "scan_file succeeded");
ok(@events > 0, "Got callback events scanning file");

my $rule2_match = grep { $_->{event} eq 'rule_match' && $_->{rule} eq 'Rule2' } @events;
ok($rule2_match, "Found rule_match for Rule2");

# Scan a buffer with no matches
@events = ();
$res = $yara->scan_buffer("nomatch here", sub {
    my ($info) = @_;
    push @events, $info;
});

is($res, 0, "scan_buffer no match succeeded");
is(scalar(@events), 0, "No events for buffer with no matches");

# Test error: scan before compile
my $yara2 = YaraFFI->new();
eval {
    $yara2->scan_buffer("data", sub {});
};
like($@, qr/Compile rules first/, "scan_buffer without compile throws error");

done_testing;
