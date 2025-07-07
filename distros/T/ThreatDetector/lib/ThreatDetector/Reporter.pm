package ThreatDetector::Reporter;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(generate_summary);
our $VERSION = '0.04';

sub generate_summary {
    my ($label, $events_ref, $fh) = @_;
    my @events = @$events_ref;

    print $fh "\n=== $label Summary ===\n";
    print $fh "Total: " . scalar(@events) . "\n";

    my (%ip_count, %uri_count);
    for my $e (@events) {
        $ip_count{ $e->{ip} }++;
        $uri_count{ $e->{uri} }++;
    }

    print $fh "Unique IPs:\n";
    print $fh " $_ ($ip_count{$_} hits)\n" for sort keys %ip_count;

    print $fh "Targeted URIs:\n";
    print $fh " $_ ($uri_count{$_} times)\n" for sort keys %uri_count;
}

1;

=head1 NAME

ThreatDetector::Reporter - Summary report generator for classified threat events

=head1 SYNOPSIS

  use ThreatDetector::Reporter qw(generate_summary);

  my @events = get_sqli_events();
  generate_summary('SQL Injection', \@events);

=head1 DESCRIPTION

This module provides a reusable summary reporting function for threat events
collected during log analysis. It is designed to work with all threat handler
modules that expose a list of collected events via a getter function.

The summary includes:

=over 4

=item * Total number of detected events

=item * List of unique IP addresses with hit counts

=item * List of targeted URIs with frequency counts

=back

=head1 FUNCTIONS

=head2 generate_summary($label, \@events)

Prints a structured summary for a specific threat type. Accepts a human-readable label
(e.g. "SQL Injection") and a reference to an array of event hashrefs.

Each event should contain at minimum the following keys:

  ip     - Source IP address
  uri    - Targeted endpoint

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=cut
