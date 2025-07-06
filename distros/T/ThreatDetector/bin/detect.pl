#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use POSIX qw(strftime);
use File::Path qw(make_path);
use ThreatDetector::Parser;
use ThreatDetector::Classifier;
use ThreatDetector::Dispatcher;

use ThreatDetector::Reporter qw(generate_summary);
use ThreatDetector::Handlers::SQLInjection qw(get_sqli_events);
use ThreatDetector::Handlers::XSS qw(get_xss_events);
use ThreatDetector::Handlers::ClientError qw(get_client_error_events);
use ThreatDetector::Handlers::CommandInjection qw(get_command_injection_events);
use ThreatDetector::Handlers::DirectoryTraversal qw(get_directory_traversal_events);
use ThreatDetector::Handlers::EncodedPayload qw(get_encoded_payload_events);
use ThreatDetector::Handlers::BotFingerprint qw(get_scanner_fingerprint_events);
use ThreatDetector::Handlers::MethodAbuse qw(get_http_method_abuse_events);
use ThreatDetector::Handlers::HeaderAbuse qw(get_header_abuse_events);
use ThreatDetector::Handlers::LoginBruteForce qw(get_login_brute_force_events);
use ThreatDetector::Handlers::RateLimiter qw(get_rate_burst_events);

use Getopt::Long;
use File::Basename;
use Time::HiRes qw(gettimeofday);
use JSON;
use File::Slurp;

# ----- CONFIG -----
my $config_file = 'config/config.json';
my $config_data = -e $config_file ? decode_json(scalar read_file($config_file)) : {};
my $date_str = strftime("%Y-%m-%d", localtime);

my $log_file   = $config_data->{logfile};
my $output_log = "$config_data->{output_log}/${date_str}_threat_results.log";
our $verbose = $config_data->{verbose};

$ThreatDetector::Handlers::SQLInjection::VERBOSE       = $verbose;
$ThreatDetector::Handlers::ClientError::VERBOSE        = $verbose;
$ThreatDetector::Handlers::CommandInjection::VERBOSE   = $verbose;
$ThreatDetector::Handlers::DirectoryTraversal::VERBOSE = $verbose;
$ThreatDetector::Handlers::XSS::VERBOSE                = $verbose;
$ThreatDetector::Handlers::EncodedPayload::VERBOSE     = $verbose;
$ThreatDetector::Handlers::BotFingerprint::VERBOSE     = $verbose;
$ThreatDetector::Handlers::MethodAbuse::VERBOSE        = $verbose;
$ThreatDetector::Parser::VERBOSE = $verbose;
$ThreatDetector::Classifier::VERBOSE = $verbose;

GetOptions(
    'logfile=s' => \$log_file,
    'verbose' => \$verbose,
);

open(my $fh, '<', $log_file) or die "Can't open $log_file: $!";
make_path($config_data->{output_log}) unless -d $config_data->{output_log};
open(my $out, '>>', $output_log) or die "Can't write to $output_log: $!";

while (my $line = <$fh>) {
    chomp $line;

    my $entry = ThreatDetector::Parser::parse_log_line($line);
    unless ($entry) {
        print "[SKIP] Could not parse: $line\n" if $verbose;
        next;
    }

    # Classify threat type
    my @threats = ThreatDetector::Classifier::classify($entry);
    next unless @threats;

    ThreatDetector::Dispatcher::dispatch($entry, @threats);

    # Raw threat log data
    for my $threat_type (@threats) {
        my ($sec, $micros) = gettimeofday;
        my $timestamp = scalar localtime($sec);

        my $log_line = "$timestamp [$threat_type] $entry->{ip} $entry->{method} $entry->{uri}";
        # print $out "$log_line\n";
        print "$log_line\n" if $verbose;
    }
}

my $hostname = `hostname`;
chomp $hostname;

print $out "\n===== Threat Summary Report: $hostname =====\n";

generate_summary("SQL Injection",       [ get_sqli_events() ], $out);
generate_summary("XSS Attempts",        [ get_xss_events() ], $out);
generate_summary("Client Errors",       [ get_client_error_events() ], $out);
generate_summary("Command Injection",   [ get_command_injection_events() ], $out);
generate_summary("Directory Traversal", [ get_directory_traversal_events() ], $out);
generate_summary("Encoded Payloads",    [ get_encoded_payload_events() ], $out);
generate_summary("Scanner Fingerprints",[ get_scanner_fingerprint_events() ], $out);
generate_summary("HTTP Method Abuse",   [ get_http_method_abuse_events() ], $out);

close($fh);
close($out);