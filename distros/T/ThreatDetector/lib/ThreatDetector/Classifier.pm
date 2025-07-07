package ThreatDetector::Classifier;

use strict;
use warnings;
use URI::Escape;

our $VERBOSE = 0;
our $VERSION = '0.04';

# SQL Injection patterns
my @sqli_patterns = (
    qr/\bUNION\s+ALL\s+SELECT\b/i,
    qr/\bUNION\s+SELECT\b/i,
    qr/\bSELECT\s+\*\s+FROM\b/i,
    qr/(?:'|")\s*or\s+\d+\s*=\s*\d+/i,
    qr/(['"]).*?\1\s*--/,
    qr/or\s+1\s*=\s*1/i,
    qr/\bsleep\s*\(/i,
    qr/\bconcat\b/i,
    qr/benchmark\s*\(/i,
);

# Command Injection
my @cmd_patterns = (
    qr/;.*\b(ls|whoami|cat|curl|wget)\b/i,
    qr/\|\s*(ls|cat|uname)/i,
    qr/(?:[;&|]\s*)(nc|bash|sh|powershell)\b/i,
    qr/(?:http|ftp):\/\/[^ ]+/i,
);

# Directory traversal
my @traversal_patterns = (
    qr/\.\.\/+/,
    qr/\%2e\%2e\//i,
    qr/\/etc\/passwd/,
);

# XSS patterns
my @xss_patterns = (
    qr/<script.*?>/i,
    qr/(?:\?|&)on(?:click|error|load|mouseover|focus|submit|keydown|keyup|blur|change)\s*=/i,
    qr/javascript:/i,
    qr/%3Cscript/i,
);

# Encoded Payloads
my @encoded_patterns = (
    qr/%[0-9a-fA-F]{2}/,  # general URL encoding
    qr/%2e/i,             # encoded .
    qr/%3c/i,             # encoded <
);

# Bad User-Agents / Scanner Signatures
my @bad_agents = (
    qr/sqlmap/i,
    qr/nikto/i,
    qr/nmap/i,
    qr/dirbuster/i,
    qr/python-requests/i,
    qr/libwww/i,
);

sub classify {
    my ($entry) = @_;
    return () unless $entry && ref $entry eq 'HASH';

    my @threats;

    push @threats, 'sql_injection' if any_match($entry->{uri}, @sqli_patterns);
    push @threats, 'client_error' if $entry->{status} =~ /^4\d\d$/;
    push @threats, 'command_injection' if any_match($entry->{uri}, @cmd_patterns);
    push @threats, 'directory_traversal' if any_match($entry->{uri}, @traversal_patterns);
    push @threats, 'xss_attempt' if any_match($entry->{uri}, @xss_patterns);
    push @threats, 'encoded_payload' if any_match($entry->{uri}, @encoded_patterns);
    push @threats, 'scanner_fingerprint' if any_match($entry->{user_agent}, @bad_agents);
    push @threats, 'http_method_abuse' if $entry->{method} =~ /^(PUT|DELETE|TRACE|CONNECT)$/;

    # TODO:
    # 9. Rate limiting / burst detection (requires time tracking outside of this module)
    # 10. Login brute-force (likely needs context or endpoint + rate info)
    # 11. Header abuse (referer, user-agent anomalies — could go here)

    return @threats;
}

sub any_match {
    my ($text, @patterns) = @_;
    for my $re (@patterns) {
        if ($text && $text =~ $re) {
            warn "[DEBUG] Matched pattern $re on: $text\n" if $VERBOSE;
            return 1;
        }
    }
    return 0;
}

1;

=head1 NAME

ThreatDetector::Classifier - Threat classification engine for parsed Apache log entries

=head1 SYNOPSIS

  use ThreatDetector::Classifier;

  my @threats = ThreatDetector::Classifier::classify($entry);

=head1 DESCRIPTION

This module analyzes structured Apache log entries (as hashrefs) and classifies them into one or more known web threat categories. The output is a list of threat types for further processing by the dispatcher.

=head1 FUNCTIONS

=head2 classify($entry)

Takes a hashref representing a parsed log entry (from Parser.pm) and returns a list of matching threat types. Returns an empty list if no known threats are found.

=head2 any_match($text, @patterns)

Internal utility function. Returns true if any regex in @patterns matches $text.

=head1 THREAT TYPES RETURNED

=over 4

=item * sql_injection

=item * client_error

=item * command_injection

=item * directory_traversal

=item * xss_attempt

=item * encoded_payload

=item * scanner_fingerprint

=item * http_method_abuse

=back

Future versions may include:

=over 4

=item * rate_burst

=item * login_bruteforce

=item * header_abuse

=back

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut
