package ThreatDetector::Dispatcher;

use strict;
use warnings;
use JSON;
use File::Basename;
use Time::HiRes qw(gettimeofday);

use ThreatDetector::Handlers::SQLInjection qw(handle_sql_injection);
use ThreatDetector::Handlers::ClientError qw(handle_client_error);
use ThreatDetector::Handlers::CommandInjection qw(handle_command_injection);
use ThreatDetector::Handlers::DirectoryTraversal qw(handle_directory_traversal);
use ThreatDetector::Handlers::XSS qw(handle_xss);
use ThreatDetector::Handlers::EncodedPayload qw(handle_encoded);
use ThreatDetector::Handlers::BotFingerprint qw(handle_scanner);
use ThreatDetector::Handlers::MethodAbuse qw(handle_http_method);

our $VERSION = '0.04';

my %handlers = (
    sql_injection => \&handle_sql_injection,
    client_error => \&handle_client_error,
    command_injection => \&handle_command_injection,
    directory_traversal => \&handle_directory_traversal,
    xss_attempt => \&handle_xss,
    encoded_payload => \&handle_encoded,
    scanner_fingerprint => \&handle_scanner,
    http_method_abuse => \&handle_http_method,
    # Will add a few more later
);

sub dispatch {
    my ($entry, @threats) =@_;
    return unless $entry && @threats;

    for my $threat (@threats) {
        if (exists $handlers{$threat}) {
            $handlers{$threat}->($entry);
        } else {
            warn "[Dispatcher] No handler for threat type: $threat\n";
        }
    }
}

1;

=head1 NAME

ThreatDetector::Dispatcher - Routes classified threats to their appropriate handler modules

=head1 SYNOPSIS

  use ThreatDetector::Dispatcher;

  ThreatDetector::Dispatcher::dispatch($entry, @threats);

=head1 DESCRIPTION

This module dispatches structured Apache log entries (parsed and classified) to the appropriate threat handler based on their threat types. Each handler is responsible for processing or logging the alert in its own way (typically as JSON output).

The dispatch system uses a mapping of known threat types to handler subroutine references. If a threat type has no matching handler, a warning is printed.

=head1 FUNCTIONS

=head2 dispatch($entry, @threats)

Given a parsed log entry (as a hashref) and a list of threat types (as strings), this function invokes the appropriate handler subroutine for each threat.

  Parameters:
    $entry   - A hashref representing the parsed log line.
    @threats - A list of strings representing classified threat types.

  Example:

    my $entry = ThreatDetector::Parser::parse_log_line($line);
    my @threats = ThreatDetector::Classifier::classify($entry);
    ThreatDetector::Dispatcher::dispatch($entry, @threats);

=head1 SUPPORTED THREAT TYPES

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

=head1 AUTHOR

Jason Hall <jason.kei.hall@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
